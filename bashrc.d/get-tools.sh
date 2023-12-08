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
    wget https://github.com/nats-io/nats-server/releases/download/v2.9.17/nats-server-v2.9.17-linux-amd64.tar.gz
    sudo tar -zxf nats-server-v2.9.17-linux-amd64.tar.gz
    sudo cp nats-server-v2.9.17-linux-amd64/nats-server /usr/bin/
    nats-server -v
    sudo groupadd --system nats && sudo useradd -s /sbin/nologin --system -g nats nats
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
    wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
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
    wget https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.57.0/sonobuoy_0.57.0_linux_"${arch}".tar.gz
    sudo tar -xzf sonobuoy_0.57.0_linux_"${arch}".tar.gz -C /usr/local/bin
}

get_postgres() {
    sudo apt update
    sudo apt install postgresql postgresql-contrib -y
    
    # Wait for PostgreSQL services to start
    while [ "$(systemctl status postgresql.service | grep Active | awk '{print $2}')" != "active" ] || [ "$(systemctl status postgresql@14-main.service | grep Active | awk '{print $2}')" != "active" ]; do
        sleep 15
    done

    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/<version>/main/postgresql.conf
    sudo -u postgres psql -c "CREATE USER "${PRODUCT}" WITH PASSWORD 'CCv75DPm59LSFdLR3CR7c7JkVnfbS7rmbmEoZf8WG5Z';"
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