## Fix bootloop 

If you encounter a bootloop and have encrypted storage, don't worry, follow the instructions below to safely resolve the issue:

1. **Sapphire GPU Tool Bootloop**  
   - Enter recovery mode.  
   - Create a new file in `/cache` named:  
     `/cache/sapphire_uninstall`  
   - **Or** open a terminal emulator and execute:
     ```shell
     touch /cache/sapphire_uninstall
     ```
   - Reboot to system

2. **Standard iUnlocker Info Tool Bootloop**  
   - Enter recovery mode.  
   - Create a new file in `/cache` named:  
     `/cache/iunlocker_standard_uninstall`  
   - **Or** open a terminal emulator and execute:
     ```shell
     touch /cache/iunlocker_standard_uninstall
     ```
   - Reboot to system
   
3. **iUnlockerGL Main Module Bootloop**  
   - Enter recovery mode.  
   - Create a new file in `/cache` named:  
     `/cache/iunlocker_uninstall`  
   - This will completely remove the iUnlockerGL module.  
   - **Or** open a terminal emulator and execute:
     ```shell
     touch /cache/iunlocker_uninstall
     ```
   - Reboot to system
