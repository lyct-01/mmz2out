#!/bin/bash

echo $(pwd)
zip -r afrmc_build.zip -X afrmc_* conf/ data/ upgrade/ include/ lib/lib* startAfrmc.sh reconnect_network.sh




