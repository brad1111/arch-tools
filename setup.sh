#!/bin/bash
for $i in scripts/; do
	chmod +x $i
	chown root:root $i
	cp $i /root
done

for $i in hooks/; do
	chown root:root $i
	cp $i /etc/pacman.d/hooks
done
