sudo ./wifi-share.sh on

sudo ./wifi-share.sh off


From example
nmcli device status


DEVICE          TYPE      STATE                   CONNECTION 
wlp2s0          wifi      connected               Private    
tailscale0      tun       connected (externally)  tailscale0 
lo              loopback  connected (externally)  lo         
docker0         bridge    connected (externally)  docker0    
p2p-dev-wlp2s0  wifi-p2p  disconnected            --         
enp0s31f6       ethernet  unavailable             --       

