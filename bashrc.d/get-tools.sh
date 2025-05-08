#!/bin/sh

get_cili() {
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

}

# --- install helm to the node ---
get_helm() {
    has_bin curl
    sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    sudo chmod +x get_helm.sh
    sudo ./get_helm.sh
}

# --- install docker ---
get_docker() {
    has_bin curl
    curl -fsSL https://get.docker.com -o get-docker.sh && sudo chmod +x get-docker.sh
    sudo ./get-docker.sh
    has_bin docker
    sudo systemctl enable docker --now
}

# --- install wireguard ---
get_wireguard() {
    printf "use your package manager to update && upgrade, then install wireguard \n note there are more steps to get wireguard working on SLES and SLEM"
}

# --- install etcdctl ---
get_etcdctl() {
    has_bin curl
    # has_bin wget
    # wget https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz
    # wait
    # tar -xvzf etcd-v3.5.0-linux-amd64
    # sudo cp sudo cp etcd-v3.5.0-linux-amd64/etcd* /usr/local/bin/
    _etcd_version=v3.5.0
    # choose either URL
    # GOOGLE_URL=https://storage.googleapis.com/etcd
    _github_url=https://github.com/etcd-io/etcd/releases/download
    _download_url=${_github_url}

    rm -f /tmp/etcd-${_etcd_version}-linux-amd64.tar.gz
    rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
    curl -L ${_download_url}/${_etcd_version}/etcd-${_etcd_version}-linux-amd64.tar.gz -o /tmp/etcd-${_etcd_version}-linux-amd64.tar.gz
    tar xzvf /tmp/etcd-${_etcd_version}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
    rm -f /tmp/etcd-${_etcd_version}-linux-amd64.tar.gz
    /tmp/etcd-download-test/etcd --version
    /tmp/etcd-download-test/etcdctl version
    /tmp/etcd-download-test/etcdutl version
    sudo cp /tmp/etcd-download-test/etcd* /usr/bin/
    etcdctl version
}

# --- install zerotier vpn ---
get_zt() {
    has_bin curl
    curl -s https://install.zerotier.com | sudo bash
    wait
    sudo zerotier-cli join YOUR_ZT_NETWORK_ID
}

# --- install nats.io ---
get_nats() {
    has_bin wget
    wget https://github.com/nats-io/nats-server/releases/download/v2.10.26/nats-server-v2.10.26-linux-amd64.tar.gz
    sudo tar -zxf nats-server-v2.10.26-linux-amd64.tar.gz
    sudo cp nats-server-v2.10.26-linux-amd64/nats-server /usr/bin/
    nats-server -v
    curl -sf https://binaries.nats.dev/nats-io/natscli/nats@latest -o install-nats.sh
    chmod +x ./install-nats.sh
    ./install-nats.sh
    sudo cp nats /usr/bin/
    sudo groupadd --system nats && sudo useradd -s /sbin/nologin --system -g nats nats
}

get_nack() {
    has_bin helm
    helm repo add nats https://nats-io.github.io/k8s/helm/charts/
    helm repo update
    helm upgrade --install nats nats/nats --set config.jetstream.enabled=true --set config.jetstream.memoryStore.enabled=true --set config.cluster.enabled=true --set jetstrea.nats.url=nats://nats.default.svc.cluster.local:4222 --set jetstream.additionalArgs={--control-loop} --wait

}

# --- install existing rancher jenkins setup ---
get_janky() {
    has_bin curl
    has_bin git
    git clone https://github.com/scriptcamp/kubernetes-jenkins #might want to mirror this
    kubectl create -namespace devops-tools
    curl FUTURE_HOME_OF_YAML_WORKLOAD_FILES maybe a second git clone repo.com/yeah
    kubectl apply repo/yeah/service-account.yaml
    kubectl apply repo/yeah/jenkins-deployment.yaml
    kubectl apply repo/yeah/jenkins-service.yaml
    kubectl apply repo/yeah/jenkins-ingress.yaml
    kubectl apply repo/yeah/jenkins-pvc.yaml
}

# --- install krew plugin for kubectl ---
get_krew() {
    has_bin git
    has_bin kubectl
    (
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
}

# --- install krew plugin for kubectl ---
get_kuttl() {
    has_bin kubectl
    kubectl krew install kuttl
}

# --- install akri into the cluster using helm ---
get_akri() {
    has_bin helm
    helm repo add akri-helm-charts https://project-akri.github.io/akri/
    helm install akri akri-helm-charts/akri --set kubernetesDistro=k3s
}

# --- install wasmcloud into the cluster using helm ---
get_wasmcloud() {
    has_bin helm
    helm repo add wasmcloud https://wasmcloud.github.io/wasmcloud-otp/
    helm install wasmcloud wasmcloud/wasmcloud-host

}

get_fluent() {
    curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh -o install-fluent.sh
    chmod +x install-fluent.sh
    # call function from host-config.sh that writes k3s-fluent-k3s.service etc config files to the right places
    # probably make it multiple functions for each of the config files
    sudo ./install-fluent.sh 
    sudo mkdir -p /etc/fluent-bit/
   #sudo vim /lib/systemd/system/k3s-fluent-k3s.service
   configure_fluent_service
   #sudo vim /etc/fluent-bit/agent.conf
   configure_fluent_agent
   #sudo vim /etc/fluent-bit/fluent-bit.conf
   configure_fluent_conf
   echo "You'll need to edit the fluent-bit.conf file to include the psql database connection information to send data to"
   wait
   sleep 12
   sudo systemctl enable k3s-fluent-k3s.service --now
}

get_go() {
    has_bin wget
    wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
    which go
    go version
}

get_kubetest() {
    go install sigs.k8s.io/kubetest/v3/cmd/kubetest@latest
    go install sigs.k8s.io/provider-aws-test-infra/kubetest2-ec2@latest
    go install sigs.k8s.io/kubetest2/kubetest2-tester-ginkgo@latest
    go install sigs.k8s.io/kubetest2/kubetest2-tester-exec@latest
    go install sigs.k8s.io/kubetest2/kubetest2-tester-node@latest
    # future go install kubetest2-k3s@latest
}

get_k3d() {
    has_bin wget
    wget https://github.com/k3d-io/k3d/releases/download/v5
}

get_k3k() {
    sudo sysctl -w fs.inotify.max_user_instances=2099999999
    sudo sysctl -w fs.inotify.max_queued_events=2099999999
    sudo sysctl -w fs.inotify.max_user_watches=2099999999
    has_bin helm
    helm repo add k3k https://rancher.github.io/k3k
    #helm repo add k3k https://enrichman.github.io/k3k
    helm repo update
    helm install --namespace k3k-system --create-namespace k3k/k3k --devel --generate-name
    wget --quiet -D - https://github.com/rancher/k3k/releases/download/v0.3.2/k3k-kubelet-linux-amd64
    chmod +x k3k-kubelet-linux-amd64
    sudo mv k3k-kubelet-linux-amd64 /usr/local/bin/k3k-kubelet
    wget https://github.com/rancher/k3k/releases/download/v0.3.2/k3kcli-linux-amd64
    chmod +x k3kcli-linux-amd64
    sudo mv k3kcli-linux-amd64 /usr/local/bin/k3kcli
    cat /proc/sys/fs/inotify/max_user_instances
    cat /proc/sys/fs/inotify/max_user_watches
    cat /proc/sys/fs/inotify/max_queued_events
}

get_capi() {
    has_bin git
    has_bin helm
    git clone https://github.com/VestigeJ/cluster-api-k3s.git
    get_clusterctl
    get_awsadm
}

get_kwasm() {
    has_bin helm
    helm repo add kwasm http://kwasm.sh/kwasm-operator/
    helm install -n kwasm --create-namespace kwasm-operator kwasm/kwasm-operator
    kubectl annotate node --all kwasm.sh/kwasm-node=true
}

get_tailscale() {
    curl -fsSL https://tailscale.com/install.sh -o install-ts.sh
    chmod +x install-ts.sh
    sudo ./install-ts.sh
}

get_sono() {
    has_bin wget
    _arch
    arch=$(if [ "$(uname -m)" = "x86_64" ]; then echo "amd64"; else echo "arm64"; fi)
    wget https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.57.3/sonobuoy_0.57.3_linux_"${arch}".tar.gz
    sudo tar -xzf sonobuoy_0.57.3_linux_"${arch}".tar.gz -C /usr/local/bin
}

get_postgres() {
    has_bin wget
    sudo apt update
    sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -;
    sudo apt install -y postgresql-15
    sudo mkdir -p /var/lib/pgsql/data/
    #sudo apt install postgresql postgresql-contrib -y
    
    # Wait for PostgreSQL services to start
    #while [ "$(systemctl status postgresql.service | grep Active | awk '{print $2}')" != "active" ] || [ "$(systemctl status postgresql@14-main.service | grep Active | awk '{print $2}')" != "active" ]; do
    #    sleep 15
    #done

    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/<version>/main/postgresql.conf
    sudo -u postgres psql -c "CREATE USER "${PRODUCT}" WITH PASSWORD '"${YOUR_PASSWORD_HERE}"';"
    sudo -u postgres createdb -O "${PRODUCT}" kubernetes
}

set_postgres() {
    _ip_to_add="${1}"
    if [- -z "$_ip_to_add" ]
    then
        echo "You forgot to pass an IP address to add to configuration"
    else
        sudo echo "host    all             all             "${_ip_to_add}"/32        scram-sha-256" | sudo tee -a /etc/postgresql/14/main/pg_hba.conf
    fi
}

get_credentialprovider() {
    sudo mkdir -p /var/lib/rancher/credentialprovider/bin/
    wget https://github.com/rancher/wharfie/releases/download/v0.6.5/config-amd64.yaml
    wget https://github.com/rancher/wharfie/releases/download/v0.6.5/ecr-credential-provider-amd64
    sudo cp config-amd64.yaml /var/lib/rancher/credentialprovider/config.yaml
    chmod +x ecr-credential-provider-amd64
    sudo cp ecr-credential-provider-amd64 /var/lib/rancher/credentialprovider/bin/
}

get_ai() {
    has_bin helm
    configure_localai
    configure_k8sgpt
    helm repo add go-skynet https://go-skynet.github.io/helm-charts/
    helm repo add k8sgpt https://charts.k8sgpt.ai/
    helm repo update
    helm install local-ai go-skynet/local-ai -f ~/local_ai.yaml 
    helm install k8sgpt-operator k8sgpt/k8sgpt-operator
    kubectl create -f ~/k8sgpt_launch.yaml

}

get_wasi() {
    has_bin wget
    _arch=$(uname -m)
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/containerd-wasm-shims-v1-lunatic-linux-"${_arch}".tar.gz   
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/containerd-wasm-shims-v1-slight-linux-"${_arch}".tar.gz
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/containerd-wasm-shims-v1-wws-linux-"${_arch}".tar.gz
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/containerd-wasm-shims-v2-spin-linux-"${_arch}".tar.gz
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/workload.yaml
    wget https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/runtime.yaml
    
    tar -xvf containerd-wasm-shims-v1-lunatic-linux-"${_arch}".tar.gz
    tar -xvf containerd-wasm-shims-v1-slight-linux-"${_arch}".tar.gz
    tar -xvf containerd-wasm-shims-v1-wws-linux-"${_arch}".tar.gz
    tar -xvf containerd-wasm-shims-v2-spin-linux-"${_arch}".tar.gz
    
    chmod +x containerd-shim-lunatic-v1
    chmod +x containerd-shim-slight-v1
    chmod +x containerd-shim-wws-v1
    chmod +x containerd-shim-spin-v2
    
    sudo cp containerd-shim-lunatic-v1 /usr/local/bin/
    sudo cp containerd-shim-slight-v1 /usr/local/bin/
    sudo cp containerd-shim-wws-v1 /usr/local/bin/
    sudo cp containerd-shim-spin-v2 /usr/local/bin/
    # call host-config function to write config.toml file
    # set_runtimes #this seems to be now not needed and should be automatically written
}

get_kubectl() {
    has_bin curl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo cp ./kubectl /usr/local/bin/
}

get_clusterctl() {
    has_bin curl
    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.9.5/clusterctl-linux-amd64 -o clusterctl
    chmod +x clusterctl
    sudo cp ./clusterctl /usr/local/bin/
}

get_awsadm() {
    has_bin curl
    curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v2.7.1/clusterawsadm-linux-amd64 -o clusterawsadm
    chmod +x clusterawsadm
    sudo cp ./clusterawsadm /usr/local/bin/
    set_awsadm
}

get_kubelet() {
    RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
    ARCH="amd64"
    DOWNLOAD_DIR="/usr/local/bin/"
    curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
    chmod +x {kubeadm,kubelet}
    sudo cp {kubeadm,kubelet} /usr/local/bin/
    cd $DOWNLOAD_DIR

    RELEASE_VERSION="v0.16.2"
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
    sudo mkdir -p /etc/systemd/system/kubelet.service.d
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    sudo systemctl enable --now kubelet
}

get_cniplugs() {
    CNI_PLUGINS_VERSION="v1.3.0"
    ARCH="amd64"
    DEST="/opt/cni/bin"
    sudo mkdir -p "$DEST"
    curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz
}

get_crictl() {
    CRICTL_VERSION="v1.28.0"
    ARCH="amd64"
    curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C /usr/local/bin/ -xz
}

get_workloads() {
    has_bin git
    git clone https://github.com/VestigeJ/qa.git
}

get_turtles() {
    has_bin helm
    has_bin kubectl
    #helm repo add jetstack https://charts.jetstack.io
    #kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.15.0/cert-manager.crds.yaml
    #helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --version v1.15.0
    helm repo add turtles https://rancher.github.io/turtles
    helm repo update
    helm install rancher-turtles turtles/rancher-turtles --version v0.8.0 -n rancher-turtles-system --dependency-update --create-namespace --set cluster-api-operator.cert-manager.enabled=true --wait --timeout 270s
}

set_selinux() {
    sudo zypper addrepo https://download.opensuse.org/repositories/security:SELinux/15.6/security:SELinux.repo
    sudo zypper refresh
    sudo zypper install container-selinux-2.231.0-150600.1.1.noarch selinux-policy-targeted selinux-policy-devel restorecond policycoreutils setools-console
    sudo restorecon -R -v /root/.ssh
    printf "SELINUX=permissive \n" > ~/config
    sudo cp ~/config /etc/selinux/
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\([^\"]*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 security=selinux selinux=1 enforcing=0\"/" /etc/default/grub
        #  echo "You'll need to use your package manager to install the necessary selinux tooling"
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo chcon -R -v system_u:object_r:usr_t:s0 ~/.ssh/

    #     sudo vim /etc/default/grub
    #     sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    #     sudo restorecon -R /*
    #     sudo restorecon /.autorelabel
    #    sudo vim /etc/selinux/config
    #    sudo reboot
}

get_milvus() {
    has_bin helm
    helm repo add milvus https://zilliztech.github.io/milvus-helm/
    helm repo update
    helm install millivoos milvus/milvus --set cluster.enabled=false --set etcd.replicaCount=1 --set minio.mode=standalone --set pulsar.enabled=false
    #steps from docs to get ui
    #kubectl get pod my-release-milvus-standalone-54c4f88cb9-f84pf --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
    #kubectl port-forward service/my-release-milvus 27017:19530
    #kubectl port-forward --address 0.0.0.0 service/my-release-milvus 27017:19530
    #Forwarding from 0.0.0.0:27017 -> 19530
    #OR OR OR OPERATOR INSTALL
    #helm install milvus-operator \
    #  -n milvus-operator --create-namespace \
    #  --wait --wait-for-jobs \
    #  https://github.com/milvus-io/milvus-operator/releases/download/v0.5.0/milvus-operator-0.5.0.tgz
    #kubectl apply -f https://raw.githubusercontent.com/milvus-io/milvus-operator/main/deploy/manifests/deployment.yaml
    #
}

get_awsack() {
    has_bin git
    bas_bin aws
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml
    mkdir -p awsack/ && cd awsack/ || return
    kubectl kustomize https://github.com/aws-controllers-k8s/s3-controller.git/config/default?ref=v1.0.17 >> ./s3-ack.yaml
    kubectl kustomize https://github.com/aws-controllers-k8s/iam-controller.git/config/default?ref=v1.3.13 >> ./iam-ack.yaml
    kubectl kustomize https://github.com/aws-controllers-k8s/ec2-controller.git/config/default?ref=v1.3.0 >> ./ec2-ack.yaml
    kubectl kustomize https://github.com/k3s-io/cluster-api-k3s.git/bootstrap/config/default?ref=v0.2.1 >> ./k3s-bootstrap.yaml
    kubectl kustomize https://github.com/k3s-io/cluster-api-k3s.git/controlplane/config/default?ref=v0.2.1 >> ./k3s-controlplane.yaml
    # kubectl apply -f https://github.com/kubernetes-sigs/cluster-api-operator/releases/latest/download/operator-components.yaml
    # need to consider choices here for simplicity or consistency
    kubectl kustomize https://github.com/kubernetes-sigs/cluster-api-operator.git/config/default/?ref=v0.14.0 >> ./cluster-api-operator.yaml # needed to patch image version to match this release tag string it defaults to dev but that won't pull
    kubectl kustomize https://github.com/rancher/cluster-api-provider-rke2.git/bootstrap/config/default?ref=v0.8.0 >> ./rke2-bootstrap.yaml
    kubectl kustomize https://github.com/rancher/cluster-api-provider-rke2.git/controlplane/config/default?ref=v0.8.0 >> ./rke2-controlplane.yaml
    set_kustomizations
}

get_latest_release() {
    curl -s -H "Accept: application/vnd.github+json" https://api.github.com/repos/rancher/k3k/releases | jq '.[].tag_name' | sort --version-sort | grep -i -e "${_branch}" | tail -n 1 # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

get_hydro() {
    go install sigs.k8s.io/hydrophone@latest
    sudo cp $HOME/go/bin/hydrophone /usr/local/bin/hydro 
    /usr/local/bin/hydro --help
}

go_nats() {
    helm repo add nats https://nats-io.github.io/k8s/helm/charts/
    helm install nats nats/nats
    wait
    kubectl exec -it deployment/nats-box -- nats pub test hi
}

get_storage() {
    echo "using stable branch for storage class..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
    echo "patching local-path storage class to be default"
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    kubectl get storageclass -A
}