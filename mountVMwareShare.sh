#!/bin/bash

sudo vmhgfs-fuse .host:/ /mnt/vmwareShare/ -o subtype=vmhgfs-fuse,allow_other

echo ""
echo "Content of the vmwareShare:"
echo "---------------------------"
echo ""

ls -la /mnt/vmwareShare
