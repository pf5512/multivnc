/*
 *  Copyright (C) 2011-2012 Christian Beier <dontmind@freeshell.org>
 *  Copyright (C) 1999 AT&T Laboratories Cambridge.  All Rights Reserved.
 *
 *  This is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This software is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this software; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
 *  USA.
 */

/*
 * sockets.c - functions to deal with sockets.
 */

#ifdef __STRICT_ANSI__
#define _BSD_SOURCE
#endif
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <assert.h>
#include <rfb/rfbclient.h>
#ifdef WIN32
#undef SOCKET
#include <winsock2.h>
#ifdef MINGW32
#define EWOULDBLOCK WSAEWOULDBLOCK
#endif
#define close closesocket
#define read(sock,buf,len) recv(sock,buf,len,0)
#define write(sock,buf,len) send(sock,buf,len,0)
#define socklen_t int
#ifdef LIBVNCSERVER_HAVE_WS2TCPIP_H
#undef socklen_t
#include <ws2tcpip.h>
#endif
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/un.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#endif
#include "tls.h"
#include "ghpringbuf.h"
#include "packet.h"

void PrintInHex(char *buf, int len);

rfbBool errorMessageOnReadFailure = TRUE;

/*
 * ReadFromRFBServer is called whenever we want to read some data from the RFB
 * server.  It is non-trivial for two reasons:
 *
 * 1. For efficiency it performs some intelligent buffering, avoiding invoking
 *    the read() system call too often.  For small chunks of data, it simply
 *    copies the data out of an internal buffer.  For large amounts of data it
 *    reads directly into the buffer provided by the caller.
 *
 * 2. Whenever read() would block, it invokes the Xt event dispatching
 *    mechanism to process X events.  In fact, this is the only place these
 *    events are processed, as there is no XtAppMainLoop in the program.
 */

rfbBool
ReadFromRFBServer(rfbClient* client, char *out, unsigned int n)
{
#undef DEBUG_READ_EXACT
#ifdef DEBUG_READ_EXACT
	char* oout=out;
	int nn=n;
	rfbClientLog("ReadFromRFBServer %d bytes\n",n);
#endif
  if (client->serverPort==-1) {
    /* vncrec playing */
    rfbVNCRec* rec = client->vncRec;
    struct timeval tv;

    if (rec->readTimestamp) {
      rec->readTimestamp = FALSE;
      if (!fread(&tv,sizeof(struct timeval),1,rec->file))
        return FALSE;

      tv.tv_sec = rfbClientSwap32IfLE (tv.tv_sec);
      tv.tv_usec = rfbClientSwap32IfLE (tv.tv_usec);

      if (rec->tv.tv_sec!=0 && !rec->doNotSleep) {
        struct timeval diff;
        diff.tv_sec = tv.tv_sec - rec->tv.tv_sec;
        diff.tv_usec = tv.tv_usec - rec->tv.tv_usec;
        if(diff.tv_usec<0) {
	  diff.tv_sec--;
	  diff.tv_usec+=1000000;
        }
#ifndef WIN32
        sleep (diff.tv_sec);
        usleep (diff.tv_usec);
#else
	Sleep (diff.tv_sec * 1000 + diff.tv_usec/1000);
#endif
      }

      rec->tv=tv;
    }
    
    return (fread(out,1,n,rec->file)<0?FALSE:TRUE);
  }
  
  if (n <= client->buffered) {
    memcpy(out, client->bufoutptr, n);
    client->bufoutptr += n;
    client->buffered -= n;
#ifdef DEBUG_READ_EXACT
    goto hexdump;
#endif
    return TRUE;
  }

  memcpy(out, client->bufoutptr, client->buffered);

  out += client->buffered;
  n -= client->buffered;

  client->bufoutptr = client->buf;
  client->buffered = 0;

  if (n <= RFB_BUF_SIZE) {

    while (client->buffered < n) {
      int i;
      if (client->tlsSession) {
        i = ReadFromTLS(client, client->buf + client->buffered, RFB_BUF_SIZE - client->buffered);
      } else {
        i = read(client->sock, client->buf + client->buffered, RFB_BUF_SIZE - client->buffered);
      }
      if (i <= 0) {
	if (i < 0) {
#ifdef WIN32
	  errno=WSAGetLastError();
#endif
	  if (errno == EWOULDBLOCK || errno == EAGAIN) {
	    /* TODO:
	       ProcessXtEvents();
	    */
	    WaitForMessage(client, 100000);
	    i = 0;
	  } else {
	    rfbClientErr("read (%d: %s)\n",errno,strerror(errno));
	    return FALSE;
	  }
	} else {
	  if (errorMessageOnReadFailure) {
	    rfbClientLog("VNC server closed connection\n");
	  }
	  return FALSE;
	}
      }
      client->buffered += i;
      client->bytesRcvd += i;
    }

    memcpy(out, client->bufoutptr, n);
    client->bufoutptr += n;
    client->buffered -= n;

  } else {

    while (n > 0) {
      int i;
      if (client->tlsSession) {
        i = ReadFromTLS(client, out, n);
      } else {
        i = read(client->sock, out, n);
      }

      if (i <= 0) {
	if (i < 0) {
#ifdef WIN32
	  errno=WSAGetLastError();
#endif
	  if (errno == EWOULDBLOCK || errno == EAGAIN) {
	    /* TODO:
	       ProcessXtEvents();
	    */
	    WaitForMessage(client, 100000);
	    i = 0;
	  } else {
	    rfbClientErr("read (%s)\n",strerror(errno));
	    return FALSE;
	  }
	} else {
	  if (errorMessageOnReadFailure) {
	    rfbClientLog("VNC server closed connection\n");
	  }
	  return FALSE;
	}
      }
      out += i;
      n -= i;
      client->bytesRcvd += i;
    }
  }

#ifdef DEBUG_READ_EXACT
hexdump:
  { int ii;
    for(ii=0;ii<nn;ii++)
      fprintf(stderr,"%02x ",(unsigned char)oout[ii]);
    fprintf(stderr,"\n");
  }
#endif

  return TRUE;
}




/**
 * This reads packets from the multicast socket into the packet buffer
 * and writes n requested bytes into the out buffer.
 */

rfbBool
ReadFromRFBServerMulticast(rfbClient* client, char *out, unsigned int n)
{
  ghpringbuf *pbuf = client->multicastPacketBuf;
  Packet p;
  
  if(client->multicastSock < 0 || !pbuf)
    return FALSE;

  /* 
     read until packet buffer (potentially) full or nothing more to read 
  */
  while(client->multicastRcvBufLen + MULTICAST_READBUF_SZ <= client->multicastRcvBufSize
	&& ghpringbuf_count(pbuf) < pbuf->capacity) {
    int r;
    r = recvfrom(client->multicastSock, client->multicastReadBuf, MULTICAST_READBUF_SZ, 0, NULL, NULL);
    if (r <= 0) {
      if (r < 0) { /* some error */
#ifdef WIN32
	errno=WSAGetLastError();
#endif
	if (errno == EWOULDBLOCK || errno == EAGAIN) { /* nothing more to read */
	  r = 0;
	  break;
	}
	else {
	  rfbClientErr("ReadFromRFBServerMulticast (%d: %s)\n", errno, strerror(errno));
	  return FALSE;
	}
      } 
      else { /* read returned 0 */
	if (errorMessageOnReadFailure) 
	  rfbClientLog("VNC server closed connection\n");
	return FALSE;
      }
    }

    /* successfully read a packet at this point */
    client->multicastBytesRcvd += r;
    p.datalen = r;
    p.data = malloc(p.datalen);
    memcpy(p.data, client->multicastReadBuf, p.datalen);

    ghpringbuf_put(pbuf, &p);

    client->multicastRcvBufLen += p.datalen;
   
#ifdef MULTICAST_DEBUG
    rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() read %d bytes from socket.\n", r);
    rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() %d packets buffered now.\n", pbuf->count);
#endif
  }

 

  /*
    now service the request of n bytes (which have to be <= what's buffered of the packet)
  */
#ifdef MULTICAST_DEBUG
  rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() bytes requested: %d \n", n);
  rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() bytes in buffer: %d \n", client->multicastRcvBufLen);
  rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() pckts in buffer: %d \n", ghpringbuf_count(pbuf));
#endif

  if (n) {
    if(ghpringbuf_at(pbuf, 0, &p)
       && n <= p.datalen
       && (client->multicastbuffered ? n <= client->multicastbuffered : 1)) {

      if(client->multicastbuffered == 0) { /* new packet to be consumed */
	client->multicastbuffered = p.datalen;
	client->multicastbufoutptr = p.data;
      }

      /* copy requested number of bytes to out buffer */
      memcpy(out, client->multicastbufoutptr, n);
      client->multicastbufoutptr += n;
      client->multicastbuffered -= n;

      if(client->multicastbuffered == 0) { /* packet consumed */ 
	client->multicastRcvBufLen -= p.datalen;
	ghpringbuf_pop(pbuf);
#ifdef MULTICAST_DEBUG
	rfbClientLog("MulticastVNC DEBUG: ReadFromRFBServerMulticast() packet consumed, now %d packets in buffer.\n", pbuf->count);
#endif
      }
    }
    else
      return FALSE;
  }

  return TRUE;
}



/*
 * Write an exact number of bytes, and don't return until you've sent them.
 */

rfbBool
WriteToRFBServer(rfbClient* client, char *buf, int n)
{
  fd_set fds;
  int i = 0;
  int j;

  if (client->serverPort==-1)
    return TRUE; /* vncrec playing */

  if (client->tlsSession) {
    /* WriteToTLS() will guarantee either everything is written, or error/eof returns */
    i = WriteToTLS(client, buf, n);
    if (i <= 0) return FALSE;

    return TRUE;
  }

  while (i < n) {
    j = write(client->sock, buf + i, (n - i));
    if (j <= 0) {
      if (j < 0) {
#ifdef WIN32
	 errno=WSAGetLastError();
#endif
	if (errno == EWOULDBLOCK ||
#ifdef LIBVNCSERVER_ENOENT_WORKAROUND
		errno == ENOENT ||
#endif
		errno == EAGAIN) {
	  FD_ZERO(&fds);
	  FD_SET(client->sock,&fds);

	  if (select(client->sock+1, NULL, &fds, NULL, NULL) <= 0) {
	    rfbClientErr("select\n");
	    return FALSE;
	  }
	  j = 0;
	} else {
	  rfbClientErr("write\n");
	  return FALSE;
	}
      } else {
	rfbClientLog("write failed\n");
	return FALSE;
      }
    }
    i += j;
  }
  return TRUE;
}



static int initSockets() {
#ifdef WIN32
  WSADATA trash;
  static rfbBool WSAinitted=FALSE;
  if(!WSAinitted) {
    int i=WSAStartup(MAKEWORD(2,0),&trash);
    if(i!=0) {
      rfbClientErr("Couldn't init Windows Sockets\n");
      return 0;
    }
    WSAinitted=TRUE;
  }
#endif
  return 1;
}

/*
 * ConnectToTcpAddr connects to the given TCP port.
 */

int
ConnectClientToTcpAddr(unsigned int host, int port)
{
  int sock;
  struct sockaddr_in addr;
  int one = 1;

  if (!initSockets())
	  return -1;

  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = host;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
#ifdef WIN32
    errno=WSAGetLastError();
#endif
    rfbClientErr("ConnectToTcpAddr: socket (%s)\n",strerror(errno));
    return -1;
  }

  if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    rfbClientErr("ConnectToTcpAddr: connect\n");
    close(sock);
    return -1;
  }

  if (setsockopt(sock, IPPROTO_TCP, TCP_NODELAY,
		 (char *)&one, sizeof(one)) < 0) {
    rfbClientErr("ConnectToTcpAddr: setsockopt\n");
    close(sock);
    return -1;
  }

  return sock;
}

int
ConnectClientToTcpAddr6(const char *hostname, int port)
{
#ifdef LIBVNCSERVER_IPv6
  int sock;
  int n;
  struct addrinfo hints, *res, *ressave;
  char port_s[10];
  int one = 1;

  if (!initSockets())
	  return -1;

  snprintf(port_s, 10, "%d", port);
  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  if ((n = getaddrinfo(hostname, port_s, &hints, &res)))
  {
    rfbClientErr("ConnectClientToTcpAddr6: getaddrinfo (%s)\n", gai_strerror(n));
    return -1;
  }

  ressave = res;
  sock = -1;
  while (res)
  {
    sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sock >= 0)
    {
      if (connect(sock, res->ai_addr, res->ai_addrlen) == 0)
        break;
      close(sock);
      sock = -1;
    }
    res = res->ai_next;
  }
  freeaddrinfo(ressave);

  if (sock == -1)
  {
    rfbClientErr("ConnectClientToTcpAddr6: connect\n");
    return -1;
  }

  if (setsockopt(sock, IPPROTO_TCP, TCP_NODELAY,
		 (char *)&one, sizeof(one)) < 0) {
    rfbClientErr("ConnectToTcpAddr: setsockopt\n");
    close(sock);
    return -1;
  }

  return sock;

#else

  rfbClientErr("ConnectClientToTcpAddr6: IPv6 disabled\n");
  return -1;

#endif
}

int
ConnectClientToUnixSock(const char *sockFile)
{
#ifdef WIN32
  rfbClientErr("Windows doesn't support UNIX sockets\n");
  return -1;
#else
  int sock;
  struct sockaddr_un addr;
  addr.sun_family = AF_UNIX;
  strcpy(addr.sun_path, sockFile);

  sock = socket(AF_UNIX, SOCK_STREAM, 0);
  if (sock < 0) {
    rfbClientErr("ConnectToUnixSock: socket (%s)\n",strerror(errno));
    return -1;
  }

  if (connect(sock, (struct sockaddr *)&addr, sizeof(addr.sun_family) + strlen(addr.sun_path)) < 0) {
    rfbClientErr("ConnectToUnixSock: connect\n");
    close(sock);
    return -1;
  }

  return sock;
#endif
}



/*
 * FindFreeTcpPort tries to find unused TCP port in the range
 * (TUNNEL_PORT_OFFSET, TUNNEL_PORT_OFFSET + 99]. Returns 0 on failure.
 */

int
FindFreeTcpPort(void)
{
  int sock, port;
  struct sockaddr_in addr;

  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);

  if (!initSockets())
    return -1;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    rfbClientErr(": FindFreeTcpPort: socket\n");
    return 0;
  }

  for (port = TUNNEL_PORT_OFFSET + 99; port > TUNNEL_PORT_OFFSET; port--) {
    addr.sin_port = htons((unsigned short)port);
    if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
      close(sock);
      return port;
    }
  }

  close(sock);
  return 0;
}


/*
 * ListenAtTcpPort starts listening at the given TCP port.
 */

int
ListenAtTcpPort(int port)
{
  return ListenAtTcpPortAndAddress(port, NULL);
}



/*
 * ListenAtTcpPortAndAddress starts listening at the given TCP port on
 * the given IP address
 */

int
ListenAtTcpPortAndAddress(int port, const char *address)
{
  int sock;
  int one = 1;
#ifndef LIBVNCSERVER_IPv6
  struct sockaddr_in addr;

  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  if (address) {
    addr.sin_addr.s_addr = inet_addr(address);
  } else {
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
  }

  if (!initSockets())
    return -1;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    rfbClientErr("ListenAtTcpPort: socket\n");
    return -1;
  }

  if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR,
		 (const char *)&one, sizeof(one)) < 0) {
    rfbClientErr("ListenAtTcpPort: setsockopt\n");
    close(sock);
    return -1;
  }

  if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    rfbClientErr("ListenAtTcpPort: bind\n");
    close(sock);
    return -1;
  }

#else
  int rv;
  struct addrinfo hints, *servinfo, *p;
  char port_str[8];

  snprintf(port_str, 8, "%d", port);

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_PASSIVE; /* fill in wildcard address if address == NULL */

  if (!initSockets())
    return -1;

  if ((rv = getaddrinfo(address, port_str, &hints, &servinfo)) != 0) {
    rfbClientErr("ListenAtTcpPortAndAddress: error in getaddrinfo: %s\n", gai_strerror(rv));
    return -1;
  }

  /* loop through all the results and bind to the first we can */
  for(p = servinfo; p != NULL; p = p->ai_next) {
    if ((sock = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) < 0) {
      continue;
    }

#ifdef IPV6_V6ONLY
    /* we have seperate IPv4 and IPv6 sockets since some OS's do not support dual binding */
    if (p->ai_family == AF_INET6 && setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY, (char *)&one, sizeof(one)) < 0) {
      rfbClientErr("ListenAtTcpPortAndAddress: error in setsockopt IPV6_V6ONLY: %s\n", strerror(errno));
      close(sock);
      freeaddrinfo(servinfo);
      return -1;
    }
#endif

    if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char *)&one, sizeof(one)) < 0) {
      rfbClientErr("ListenAtTcpPortAndAddress: error in setsockopt SO_REUSEADDR: %s\n", strerror(errno));
      close(sock);
      freeaddrinfo(servinfo);
      return -1;
    }

    if (bind(sock, p->ai_addr, p->ai_addrlen) < 0) {
      close(sock);
      continue;
    }

    break;
  }

  if (p == NULL)  {
    rfbClientErr("ListenAtTcpPortAndAddress: error in bind: %s\n", strerror(errno));
    return -1;
  }

  /* all done with this structure now */
  freeaddrinfo(servinfo);
#endif

  if (listen(sock, 5) < 0) {
    rfbClientErr("ListenAtTcpPort: listen\n");
    close(sock);
    return -1;
  }

  return sock;
}


/*
 * AcceptTcpConnection accepts a TCP connection.
 */

int
AcceptTcpConnection(int listenSock)
{
  int sock;
  struct sockaddr_in addr;
  socklen_t addrlen = sizeof(addr);
  int one = 1;

  sock = accept(listenSock, (struct sockaddr *) &addr, &addrlen);
  if (sock < 0) {
    rfbClientErr("AcceptTcpConnection: accept\n");
    return -1;
  }

  if (setsockopt(sock, IPPROTO_TCP, TCP_NODELAY,
		 (char *)&one, sizeof(one)) < 0) {
    rfbClientErr("AcceptTcpConnection: setsockopt\n");
    close(sock);
    return -1;
  }

  return sock;
}


/*
 * SetNonBlocking sets a socket into non-blocking mode.
 */

rfbBool
SetNonBlocking(int sock)
{
#ifdef WIN32
  unsigned long block=1;
  if(ioctlsocket(sock, FIONBIO, &block) == SOCKET_ERROR) {
    errno=WSAGetLastError();
#else
  int flags = fcntl(sock, F_GETFL);
  if(flags < 0 || fcntl(sock, F_SETFL, flags | O_NONBLOCK) < 0) {
#endif
    rfbClientErr("Setting socket to non-blocking failed: %s\n",strerror(errno));
    return FALSE;
  }
  return TRUE;
}



/*
 * SetDSCP sets a socket's IP QoS parameters aka Differentiated Services Code Point field
 */

rfbBool
SetDSCP(int sock, int dscp)
{
#ifdef WIN32
  rfbClientErr("Setting of QoS IP DSCP not implemented for Windows\n");
  return TRUE;
#else
  int level, cmd;
  struct sockaddr addr;
  socklen_t addrlen = sizeof(addr);

  if(getsockname(sock, &addr, &addrlen) != 0) {
    rfbClientErr("Setting socket QoS failed while getting socket address: %s\n",strerror(errno));
    return FALSE;
  }

  switch(addr.sa_family)
    {
#if defined LIBVNCSERVER_IPv6 && defined IPV6_TCLASS
    case AF_INET6:
      level = IPPROTO_IPV6;
      cmd = IPV6_TCLASS;
      break;
#endif
    case AF_INET:
      level = IPPROTO_IP;
      cmd = IP_TOS;
      break;
    default:
      rfbClientErr("Setting socket QoS failed: Not bound to IP address");
      return FALSE;
    }

  if(setsockopt(sock, level, cmd, (void*)&dscp, sizeof(dscp)) != 0) {
    rfbClientErr("Setting socket QoS failed: %s\n", strerror(errno));
    return FALSE;
  }

  return TRUE;
#endif
}



/*
 * StringToIPAddr - convert a host string to an IP address.
 */

rfbBool
StringToIPAddr(const char *str, unsigned int *addr)
{
  struct hostent *hp;

  if (strcmp(str,"") == 0) {
    *addr = htonl(INADDR_LOOPBACK); /* local */
    return TRUE;
  }

  *addr = inet_addr(str);

  if (*addr != -1)
    return TRUE;

  if (!initSockets())
	  return -1;

  hp = gethostbyname(str);

  if (hp) {
    *addr = *(unsigned int *)hp->h_addr;
    return TRUE;
  }

  return FALSE;
}


/*
 * Test if the other end of a socket is on the same machine.
 */

rfbBool
SameMachine(int sock)
{
  struct sockaddr_in peeraddr, myaddr;
  socklen_t addrlen = sizeof(struct sockaddr_in);

  getpeername(sock, (struct sockaddr *)&peeraddr, &addrlen);
  getsockname(sock, (struct sockaddr *)&myaddr, &addrlen);

  return (peeraddr.sin_addr.s_addr == myaddr.sin_addr.s_addr);
}


/*
 * Print out the contents of a packet for debugging.
 */

void
PrintInHex(char *buf, int len)
{
  int i, j;
  char c, str[17];

  str[16] = 0;

  rfbClientLog("ReadExact: ");

  for (i = 0; i < len; i++)
    {
      if ((i % 16 == 0) && (i != 0)) {
	rfbClientLog("           ");
      }
      c = buf[i];
      str[i % 16] = (((c > 31) && (c < 127)) ? c : '.');
      rfbClientLog("%02x ",(unsigned char)c);
      if ((i % 4) == 3)
	rfbClientLog(" ");
      if ((i % 16) == 15)
	{
	  rfbClientLog("%s\n",str);
	}
    }
  if ((i % 16) != 0)
    {
      for (j = i % 16; j < 16; j++)
	{
	  rfbClientLog("   ");
	  if ((j % 4) == 3) rfbClientLog(" ");
	}
      str[i % 16] = 0;
      rfbClientLog("%s\n",str);
    }

  fflush(stderr);
}

int WaitForMessage(rfbClient* client,unsigned int usecs)
{
  fd_set fds;
  struct timeval timeout;
  int num;
  int maxfd; 

  if (client->serverPort==-1)
    {
      /* playing back vncrec file */
      client->serverMsg = TRUE;
      return 1;
    }

  client->serverMsg = client->serverMsgMulticast = FALSE;
  
  timeout.tv_sec=(usecs/1000000);
  timeout.tv_usec=(usecs%1000000);

  FD_ZERO(&fds);
  FD_SET(client->sock,&fds);
  maxfd = client->sock;
  if(client->multicastSock >= 0 && !client->multicastDisabled)
    {
      FD_SET(client->multicastSock,&fds);
      maxfd = max(client->sock, client->multicastSock);
    }

  num=select(maxfd+1, &fds, NULL, NULL, &timeout);
  if(num<0) {
#ifdef WIN32
    errno=WSAGetLastError();
#endif
    rfbClientLog("Waiting for message failed: %d (%s)\n",errno,strerror(errno));
    return num;
  }

  if(FD_ISSET(client->sock, &fds))
    client->serverMsg = TRUE;
  if(client->multicastSock >= 0 && FD_ISSET(client->multicastSock, &fds))
    client->serverMsgMulticast = TRUE;
  if(client->multicastPacketBuf && ghpringbuf_count(client->multicastPacketBuf)) {
    client->serverMsgMulticast = TRUE;
    ++num;
  }

  return num;
}


int CreateMulticastSocket(struct sockaddr_storage multicastSockAddr, int so_recvbuf)
{
  int sock; 
  struct sockaddr_storage localAddr;
  int optval;
  socklen_t optval_len = sizeof(optval);
  int dfltrcvbuf;

  if (!initSockets())
    return -1;

  localAddr = multicastSockAddr;
  /* set source addr of localAddr to ANY, 
     the rest is the same as in multicastSockAddr */
  if(localAddr.ss_family == AF_INET) 
    ((struct sockaddr_in*) &localAddr)->sin_addr.s_addr = htonl(INADDR_ANY);
  else
    if(localAddr.ss_family == AF_INET6)
       ((struct sockaddr_in6*) &localAddr)->sin6_addr = in6addr_any;
    else
      {
	rfbClientErr("CreateMulticastSocket: neither IPv4 nor IPv6 address received\n");
	return -1;
      }

 
  optval = 1;
  if((sock = socket(localAddr.ss_family, SOCK_DGRAM, 0)) < 0)
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error creating socket: %s\n", strerror(errno));
      return -1;
    }

  optval = 1;
  if(setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,(char*)&optval,sizeof(optval)) < 0) 
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error setting reuse addr: %s\n", strerror(errno));
      close(sock);
      return -1;
    } 

  /* get/set socket receive buffer */
  if(getsockopt(sock, SOL_SOCKET, SO_RCVBUF,(char*)&optval, &optval_len) <0)
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error getting rcv buf size: %s\n", strerror(errno));
      close(sock);
      return -1;
    } 
  dfltrcvbuf = optval;
  optval = so_recvbuf;
  if(setsockopt(sock,SOL_SOCKET,SO_RCVBUF,(char*)&optval,sizeof(optval)) < 0) 
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error setting rcv buf size: %s\n", strerror(errno));
      close(sock);
      return -1;
    } 
  if(getsockopt(sock, SOL_SOCKET, SO_RCVBUF,(char*)&optval, &optval_len) <0)
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error getting set rcv buf size: %s\n", strerror(errno));
      close(sock);
      return -1;
    } 
  rfbClientLog("MulticastVNC: tried to set socket receive buffer from %d to %d, got %d\n",
	       dfltrcvbuf, so_recvbuf, optval);


  if(bind(sock, (struct sockaddr*)&localAddr, sizeof(localAddr)) < 0)
    {
#ifdef WIN32
      errno=WSAGetLastError();
#endif
      rfbClientErr("CreateMulticastSocket: error binding socket: %s\n", strerror(errno));
      close(sock);
      return -1;
    }

  
  /* Join the multicast group. We do this seperately for IPv4 and IPv6. */
  if(multicastSockAddr.ss_family == AF_INET)
    {
      struct ip_mreq multicastRequest;  
 
      memcpy(&multicastRequest.imr_multiaddr,
	     &((struct sockaddr_in*) &multicastSockAddr)->sin_addr,
	     sizeof(multicastRequest.imr_multiaddr));

      multicastRequest.imr_interface.s_addr = htonl(INADDR_ANY);

      if(setsockopt(sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char*) &multicastRequest, sizeof(multicastRequest)) < 0)
        {
#ifdef WIN32
	  errno=WSAGetLastError();
#endif
	  rfbClientErr("CreateMulticastSocket: error joining IPv4 multicast group: %s\n", strerror(errno));
	  close(sock);
	  return -1;
        }
    }
  else 
    if(multicastSockAddr.ss_family == AF_INET6)
      {
	struct ipv6_mreq multicastRequest;  

	memcpy(&multicastRequest.ipv6mr_multiaddr,
	       &((struct sockaddr_in6*) &multicastSockAddr)->sin6_addr,
	       sizeof(multicastRequest.ipv6mr_multiaddr));

	multicastRequest.ipv6mr_interface = 0;

	if(setsockopt(sock, IPPROTO_IPV6, IPV6_JOIN_GROUP, (char*) &multicastRequest, sizeof(multicastRequest)) < 0)
	  {
#ifdef WIN32
  	    errno=WSAGetLastError();
#endif
	    rfbClientErr("CreateMulticastSocket: error joining IPv6 multicast group: %s\n", strerror(errno));
	    close(sock);
	    return -1;
	  }
      }
    else
      {
	rfbClientErr("CreateMulticastSocket: neither IPv6 nor IPv6 specified");
	close(sock);
	return -1;
      }

  /* this is important for ReadFromRFBServerMulticast() */
  if(!SetNonBlocking(sock)) {
    close(sock);
    return -1;
  }
    
  return sock;
}
