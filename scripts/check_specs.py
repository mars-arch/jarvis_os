import os
import platform

def get_raspberry_pi_specs():
    # Get CPU information
    cpu_info = os.popen("cat /proc/cpuinfo").read()
    
    # Get memory information
    mem_info = os.popen("free -h").read()
    
    # Get OS information
    os_info = platform.uname()
    
    # Get hard drive information
    disk_info = os.popen("lsblk -o NAME,SIZE,MOUNTPOINT").read()
    
    # Get GPIO information
    gpio_info = os.popen("gpio readall").read()
    
    print("Raspberry Pi Specifications:")
    print("\nCPU Information:\n", cpu_info)
    print("\nMemory Information:\n", mem_info)
    print("\nOS Information:\n", os_info)
    print("\nHard Drive Information:\n", disk_info)
    print("\nGPIO Information:\n", gpio_info)

if __name__ == "__main__":
    get_raspberry_pi_specs()
