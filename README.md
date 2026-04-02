# docker-kdc

Docker Image packaging for Kerberos KDC (Key Distribution Center) with HTTP only access and LDAP backend support.

## Overview

This Docker image provides a containerized Kerberos KDC service that integrates with LDAP for user management. It's designed for secure authentication in networked environments without requiring complex on-premises infrastructure.

## Features

- **Kerberos KDC**: Complete Key Distribution Center implementation
- **LDAP Backend**: User and principal management through LDAP
- **HTTP Access**: REST API for KDC operations
- **Containerized**: Easy deployment with Docker
- **Configuration**: Flexible setup through environment variables

## Getting Started

### Prerequisites

- Docker
- LDAP server with support for Novell Kerberos Schema

### Quick Start

```bash
docker build -t docker-kdc .
docker run \
  -p 8000:8000 \
  --env "LDAP_BIND_PW=secret" \
  --env "KRB5_REALM=EXAMPLE.COM" \
  --env "KRB5_STASH_PW=secret" \
  --name kdc \
  docker-kdc
```
