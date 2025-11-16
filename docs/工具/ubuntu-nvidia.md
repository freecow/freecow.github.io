---
aliases: 
tags: 
date_modified: 
date: 2025-11-16
---

# Ubuntu-NVIDIA

## 说明

在Ubuntu上安装NVIDIA显卡，并配置相应的CUDA+cuDNN，部署Docker

Nvidia 驱动程序：Nvidia的硬件驱动程序，安装之前请找出您的显卡型号  

CUDA Toolkit：包含库、编译器、开发工具和示例、CUDA 运行时等

cuDNN：针对DNN计算高度优化的GPU加速库

‍

## 安装NVIDIA驱动

参考地址

```bash
https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/index.html
```

由于Ubuntu预构建了Nvidia驱动程序包，因此始终建议使用内置

```bash
# 查看GPU型号
lspci | grep -i nvidia

# 查看系统版本
lsb_release -a

# 查找驱动
sudo ubuntu-drivers --gpgpu list

# 先检测推荐驱动版本
sudo ubuntu-drivers devices

# 如果无GUI画面，安装open意义不大
# nvidia-driver-550支持12.4，570支持12.8
# 如果是Ubuntu 24.04以上版本
sudo apt-get install -y nvidia-driver-550

# 如果是Ubuntu 22.04，可能会报错Unable to locate package nvidia-driver-550-open
# 如果对于GPGPU计算/CUDA/挖矿，推荐使用稳定的闭源驱动 nvidia-driver-535
sudo apt update
sudo apt install nvidia-driver-535

# 验证驱动是否生效
nvidia-smi
```

如果报NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running

可能是驱动未加载成功或未正确安装，需要清除驱动—>安装推荐—>重启—>验证，以下是清除驱动

```bash
# 检查当前驱动状态，如果未返回nvidia相关内容，则驱动模块未加载成功
dkms status
lsmod | grep nvidia

# 清除旧驱动残留
sudo apt-get remove --purge '^nvidia-.*'
sudo apt-get autoremove
sudo apt-get autoclean

# 重启
sudo reboot

# 再返回上一步进行安装
```

如果报Failed to initialize NVML: Driver/library version mismatch，建议重启

如果重启也不行，手动加载nvidia内核模块

```bash
# 关闭显示管理
sudo service lightdm stop

# Unload the NVIDIA modules
sudo rmmod nvidia_uvm
sudo rmmod nvidia_drm
sudo rmmod nvidia

# Reload the NVIDIA module
sudo modprobe nvidia

# Restart your display manager
sudo service lightdm start

# Then try running nvidia-smi again
```

## 安装CUDA

官方默认安装命令的局限

```bash
# 以下安装命令，安装的是较老版本的CUDA Toolkit（如CUDA 11.5）
# 如果想使用完整的新版本功能（如 PyTorch、TensorFlow、KASPA 挖矿等），建议手动安装官方CUDA Toolkit 12.x
apt install nvidia-cuda-toolkit
```

参考地址

```bash
# 最新版本
https://developer.nvidia.com/cuda-downloads

# 与nvidia-535驱动版本推荐适配CUDA 12.2
https://developer.nvidia.com/cuda-12-2-0-download-archive

# 选择顺序
Linux → x86_64 → Ubuntu → 22.04 → deb (local)
```

按照官网生成的命令安装

```bash
# 下载
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin

sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600

# 下载
wget https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.0-535.54.03-1_amd64.deb

# 安装源
sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.0-535.54.03-1_amd64.deb

# 安装GPG Key
sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/

# 安装cuda
sudo apt-get update
sudo apt-get -y install cuda

# 检查cuda版本
nvcc --version
```

‍

## 安装cuDNN

必要性

- 使用 PyTorch、TensorFlow、JAX 、ONNXRuntime等深度学习框架依赖cuDNN 加速卷积

参考地址

```bash
https://developer.nvidia.com/rdp/cudnn-archive

# 选择版本匹配CUDA 12.2
cuDNN 8.9.x for CUDA 12.2

# 登录下载
cudnn-local-repo-ubuntu2204-8.9.7.29_1.0-1_amd64.deb
```

安装步骤

```bash
# 安装源
sudo dpkg -i cudnn-local-repo-ubuntu2204-8.9.7.29_1.0-1_amd64.deb

# 根据提示安装key
sudo cp /var/cudnn-local-repo-ubuntu2204-8.9.7.29/cudnn-local-08A7D361-keyring.gpg /usr/share/keyrings/

# 安装
sudo apt-get update
sudo apt install libcudnn8 libcudnn8-dev

# 检查cudnn版本
dpkg -l | grep cudnn
```

## 环境变量

```bash
echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> ~/.bashrc

source ~/.bashrc
```

‍

## 安装Docker

```bash
# 安装源
sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 安装docker
sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io

# 安装docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

‍

## 安装NVIDIA Container Toolkit

```bash
# 添加GPG密钥
sudo apt update
sudo apt install -y curl gnupg ca-certificates

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo tee /etc/apt/keyrings/nvidia-container-toolkit.asc >/dev/null

sudo chmod a+r /etc/apt/keyrings/nvidia-container-toolkit.asc

# 添加源
distribution=$(
  . /etc/os-release
  echo $ID$VERSION_ID
)

echo "deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit.asc] https://nvidia.github.io/libnvidia-container/stable/deb/amd64/ /" |
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

# 安装nvidia docker
sudo apt update
sudo apt install -y nvidia-container-toolkit

# 配置Runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 验证docker daemon是否正在使用nvidia驱动程序
sudo docker info | grep -i nvidia

# 测试
sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi

```

‍

## 测试PyTorch与CUDA

```bash
# 安装预置软件包
sudo apt-get install python3-pip
sudo apt install python3.10-venv

# 配置虚拟环境
python3 -m venv ~/test
source ~/test/bin/activate

# 安装PyTorch
pip install --upgrade --force-reinstall --no-cache-dir \
    torch==2.5.1 torchaudio torchvision triton \
    --index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 查看组件版本
python -c "import sys; print(f'Python Version: {sys.version}'); import torch; print(f'Torch Version: {torch.__version__}'); print(f'CUDA available? {torch.cuda.is_available()}'); print(f'GPU Name: {torch.cuda.get_device_name(0)}'); print(f'GPU Memroy: {round(torch.cuda.get_device_properties(0).total_memory  / 1024 / 1024 / 1024)} GB')"

# 输出
Python Version: 3.12.2 | packaged by conda-forge | (main, Feb 16 2024, 20:50:58) [GCC 12.3.0]
Torch Version: 2.5.1+cu124
CUDA available? True
GPU Name: NVIDIA GeForce RTX 3090
GPU Memroy: 23 GB

# 张量测试
python
>>> import torch
>>> x = torch.rand(5, 3)
>>> print(x)
tensor([[0.4730, 0.8510, 0.9379],
        [0.3746, 0.3402, 0.0104],
        [0.3162, 0.5297, 0.8867],
        [0.7442, 0.3839, 0.4191],
        [0.0578, 0.3556, 0.8193]])
>>> exit();
```

‍

## Nvidia-SMI信息含义

Fan：显示风扇转速，数值在0到100%之间，是计算机的期望转速，如果计算机不是通过风扇冷却或者风扇坏了，显示出来就是N/A  
Temp：显卡内部的温度，单位是摄氏度  
Perf：表征性能状态，从P0到P12，P0表示最大性能，P12表示状态最小性能  
Pwr：能耗表示  
Bus-Id：涉及GPU总线的相关信息  
Disp.A：是Display Active的意思，表示GPU的显示是否初始化  
Memory Usage：显存的使用率  
Volatile GPU-Util：浮动的GPU利用率  
Compute M：计算模式

‍

## FAQ

Unable to determine the path to install the libglvnd EGL vendor library config files

```bash
sudo apt install libglvnd-dev
sudo apt install pkg-config
```

‍

ImportError: libGL.so.1: cannot open shared object file: No such file or directory

```bash
sudo apt-get update
sudo apt-get install libgl1-mesa-glx
```

‍

Failed to initialize NVML: Driver/library version mismatch

```bash
# 先重启试试
reboot

# 原因NVIDIA内核驱动版本与系统驱动不一致
# 卸载驱动
sudo /usr/bin/nvidia-uninstall
sudo apt-get --purge remove nvidia-*
sudo apt-get purge nvidia*
sudo apt-get purge libnvidia*
sudo apt autoremove

# 安装驱动
lspci | grep -e VGA
sudo ubuntu-drivers autoinstall

# 重启并验证
sudo reboot
nvidia-smilsmod | grep nvidia
```

‍

系统启动后nvidia-smi显示xorg占用

```bash
# 删除nvidia显卡检测占用
cd /usr/share/X11/xorg.conf.d
mv 10-nvidia.conf 10-nvidia.conf.bak
reboot
```

‍

Ubuntu安装T4驱动建议

```bash
# 检查可用的NVIDIA驱动版本
sudo ubuntu-drivers --gpgpu list

# 推荐选择535-server是针对服务器稳定性优化的版本
# 更高版本如570-server也可选，但要注意兼容性（特别是配合CUDA 和 vLLM、PyTorch等）
sudo apt install nvidia-driver-535-server

# 安装cuda
# nvidia-driver-535对应CUDA12.2最佳兼容
wget https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run

# 安装过程中取消驱动安装（你已安装535），只选择 CUDA Toolkit 和 Samples
sudo sh cuda_12.2.0_535.54.03_linux.run

# 设置环境变量
export PATH=/usr/local/cuda-12.2/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64:$LD_LIBRARY_PATH

# 安装cudnn
# cuDNN 8.9.4是最常用于CUDA12.2的cuDNN
# cuDNN 8.9.7推荐用于driver 535系列
# https://developer.nvidia.com/rdp/cudnn-archive
下载cudnn-linux-x86_64-8.9.4.25_cuda12-archive.tar.xz
tar -xvf cudnn-linux-x86_64-8.9.4.25_cuda12-archive.tar.xz
cd cudnn-linux-x86_64-8.9.4.25_cuda12-archive
sudo cp include/* /usr/local/cuda/include/
sudo cp lib/* /usr/local/cuda/lib64/

# 检查版本
nvcc --version
cat /usr/local/cuda/include/cudnn_version.h | grep CUDNN_MAJOR -A 2

```

‍

Ubuntu22.04.3安装T4驱动报Kernel Build Error

```bash
# 最新补丁
sudo apt update
sudo apt upgrade

# 安装预先需要的软件包
sudo apt install build-essential
sudo apt install linux-headers-$(uname -r)

# 查看支持的驱动
sudo apt-get install ubuntu-drivers-common
sudo ubuntu-drivers devices

# 安装NVIDIA驱动
sudo apt install nvidia-driver-535
sudo reboot

# 查看版本
nvidia-smi
# 显示驱动为535.129.03，支持CUDA最高版本为12.2
```

‍

报错：root:aplay command not found

正常现象，属于声卡未检测到

```bash
# 问题
root@g103:~# sudo ubuntu-drivers --gpgpu list
This is gpgpu mode
ERROR:root:aplay command not found

# 解决
sudo apt update
sudo apt install alsa-utils
```

‍

报错：E: Unable to locate package nvidia-driver-535

```bash
# 如果/etc/apt/sources.list为空，则需要补充清华源
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF

# 更新
sudo apt update
```
