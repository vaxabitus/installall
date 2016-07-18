#!/usr/bin/python

import time
import getopt
import socket
import sys
import re

proprties = 'mstore.properties'

from java.io import FileInputStream

propInputStream = FileInputStream(properties)
configProps = Properties()
configProps.load(propInputStream)

adminUsername=configProps.get("admin.username")
adminPassword=configProps.get("admin.password")
adminURL=configProps.get("admin.url")
domainDir = configProps.get("domain.dir")
domainName = configProps.get("domain.name")
newDomain = domainDir + '/' + domain
listenAddress = socket.gethostname()

readTemplate('mstoreTemplate.jar')
cd('Servers/AdminServer')
set('ListenAddress',listenAddress)
set('ListenPort', 7001)
create('AdminServer','SSL')
cd('SSL/AdminServer')
set('Enabled', 'False')
set('ListenPort', 7002)
