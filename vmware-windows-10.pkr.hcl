# VM Section
# ----------

variable "autounattend" {
  type    = string
  default = "./scripts/Autounattend.xml"
}

variable "disk_size" {
  type    = string
  default = "60G"
}

variable "disk_type_id" {
  type    = string
  default = "1"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:69efac1df9ec8066341d8c9b62297ddece0e6b805533fdb6dd66bc8034fba27a"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "restart_timeout" {
  type    = string
  default = "5m"
}

variable "vm_name" {
  type    = string
  default = "windows10"
}

variable "vmx_version" {
  type    = string
  default = "14"
}

variable "winrm_timeout" {
  type    = string
  default = "6h"
}

# WMware Section
# --------------

variable "iso_url" {
  type    = string
  default = "./assets/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
}

# Proxmox Section
# ---------------

variable "pve_username" {
  type    = string
  default = "root"
}

variable "pve_token" {
  type    = string
  default = "secret"
}

variable "pve_url" {
  type    = string
  default = "https://127.0.0.1:8006/api2/json"
}

variable "iso_file"  {
  type    = string
  default = "local:iso/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
}

variable "vm_id" {
  type    = string
  default = "9000"
}

# VMWARE image section
# --------------------

source "vmware-iso" "windows10" {
  boot_command      = [ "<spacebar><spacebar>" ]
  boot_wait         = "6m"
  communicator      = "winrm"
  cpus              = 2
  disk_adapter_type = "lsisas1068"
  disk_size         = "${var.disk_size}"
  disk_type_id      = "${var.disk_type_id}"
  floppy_files      = [
    "${var.autounattend}", 
    "./floppy/WindowsPowershell.lnk", 
    "./floppy/PinTo10.exe", 
    "./scripts/fixnetwork.ps1", 
    "./scripts/disable-screensaver.ps1", 
    "./scripts/disable-winrm.ps1", 
    "./scripts/enable-winrm.ps1", 
    "./scripts/microsoft-updates.bat", 
    "./scripts/win-updates.ps1"
  ]
  guest_os_type     = "windows9-64"
  headless          = "${var.headless}"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  memory            = "${var.memory}"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  version           = "${var.vmx_version}"
  vm_name           = "${var.vm_name}"
  vmx_data = {
    "RemoteDisplay.vnc.enabled" = "false"
    "RemoteDisplay.vnc.port"    = "5900"
  }
  vmx_remove_ethernet_interfaces = true
  vnc_port_max                   = 5980
  vnc_port_min                   = 5900
  winrm_password                 = "vagrant"
  winrm_timeout                  = "${var.winrm_timeout}"
  winrm_username                 = "vagrant"
  format = "ova"
}

# Proxmox image section
# ---------------------

source "proxmox-iso" "windows10" {
  proxmox_url = "${var.pve_url}"
  username = "${var.pve_username}"
  token = "${var.pve_token}"
  node =  "pve"
  iso_checksum = "${var.iso_checksum}"
  iso_file = "${var.iso_file}"
  insecure_skip_tls_verify = true
  boot_command      = [ "" ]
  boot_wait         = "6m"
  communicator      = "winrm"
  winrm_password    = "vagrant"
  winrm_timeout     = "${var.winrm_timeout}"
  winrm_username    = "vagrant"
  cores             = "${var.cpu}"
  memory            = "${var.memory}"
  vm_name           = "${var.vm_name}"
  vm_id             = "${var.vm_id}"
  os        = "win10"
  network_adapters {
    model = "e1000"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-pci"
  disks {
    type = "scsi"
    disk_size  = "${var.disk_size}"
    storage_pool = "local-lvm"
    storage_pool_type = "lvm-thin"
    format = "raw"
  }
  additional_iso_files  {
      device= "sata1"
      iso_file= "local:iso/virtio-win-0.1.215.iso"
      iso_checksum= "b9d8442c53e2383b60e49905a9e5911419a253c6a1838be3ea90c7209b26b5d7"
      unmount= true
  }
  additional_iso_files {
        device= "sata2"
        iso_file= "local:iso/Autounattend-win10.iso"
        iso_checksum= "8df7853e6e737adb5f4aef18e4c9cf5efd5820f640ed02f7105eff9fd4763f0e"
        unmount= true
  }
  template_name = "${var.vm_name}"
  template_description = "Windows 10 template"
}

build {
  sources = [
    "source.vmware-iso.windows10", 
    "source.proxmox-iso.windows10"
  ]

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    remote_path     = "/tmp/script.bat"
    scripts         = [
      "./scripts/enable-rdp.bat"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "./scripts/vm-guest-tools.ps1"
    ]
    only = [ 
      "vmware-iso.windows10", 
      "null.vagrant" 
    ]
  }

  provisioner "windows-restart" {
    restart_timeout = "${var.restart_timeout}"
  }

#  provisioner "powershell" {
#    scripts = [
#      "./scripts/set-powerplan.ps1"
#    ]
#  }

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    remote_path     = "/tmp/script.bat"
    scripts         = [
      "./scripts/compile-dotnet-assemblies.bat", 
      "./scripts/set-winrm-automatic.bat", 
      "./scripts/uac-enable.bat"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "./scripts/win-updates.ps1"
    ]
  }

#  post-processor "vagrant" {
#    keep_input_artifact  = false
#    output               = "windows_10_<no value>.box"
#    vagrantfile_template = "vagrantfile-windows_10.template"
#  }
}