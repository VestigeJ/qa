#!/bin/bash
## February 2025 needs to be updated for latest windows versions
function make_wincry(){
        local instance_count="${1:-1}"
        local ami="${2:-00aba64d12d376282}" # win22 us-west-2 oregon
        local instance_type="${3:-t3.large}"
        local ebs_size="${4:-50}"
        local key_name="${5:-your-key}"
        local random_num=$(jot -r 1 10 99)
        local path_to_config='<powershell> Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0;Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0;Start-Service sshd;Set-Service -Name sshd -StartupType 'Automatic';
$authorizedKey="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhki1DL6KLXA2JBUU+6PiP+xs+4btCFDo7Tf1S9bXAgSMAOkM6mk/
jkdL+5zIDnzTfulpqu+61o2TLUdqiWVFj0ftOcwQ0A5buQLOZtHzUrdD6jnxhP92
3QIDAQAB
-----END PUBLIC KEY-----";
Add-Content -Force -Path C:\ProgramData\ssh\administrators_authorized_keys -Value '\$authorizedKey';icacls.exe ""c:\ProgramData\ssh\administrators_authorized_keys"" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F"";
Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart;
    </powershell><persist>true</persist>'
        local name_tag='ResourceType=instance,Tags=[{Key=Name,Value=justin-qa-'$random_num'}]'
        # echo "$path_to_config"
        aws ec2 run-instances \
    --image-id ami-"$ami" \
    --count "$instance_count" \
    --instance-type "$instance_type" \
    --key-name "$key_name" \
    --tag-specifications "$name_tag" \
    --block-device-mapping DeviceName=/dev/sda1,Ebs={VolumeSize="$ebs_size"} \
        --security-group-ids sg-cab5ea \
    --subnet-id vpc-84f6  \
    --subnet-id subnet-518 \
    --user-data "$path_to_config" 
}