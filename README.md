# Offline scripts.
My computer knowledge is limited. My paranoia is not.  
So...

### A foolproof aproach:
- Unencrypted data appears only on an offline system.  
- The system needs to be eliminated right after.  

### I did it my way.
1. Boot form  archlinux.iso.  
1. Sync date & time. (for https) 
*( timedatectl set-ntp true )*
1. Get git.  
1. Clone this repo.  
1. Install what needed.
1. Cut off all the wires.  
1. Get busy.  
1. Format all the blk devices that have been used.

## Scripts:
#### btc-addr-gen.sh  
##### Bulk generatetion of btc addresses.  
entropy source: *gpg --gen-random*  
public formats: *uncompressed; compressed.*  
privet formats: *wif; wif-comppressed; hex.*  
QR png: *qrencode*  
QR text: *qrc*  
(With text based QR-codes, you need but terminal for mobile phone scanner.)
