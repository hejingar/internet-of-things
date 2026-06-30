# Inception-of-Things (IoT) — Checklist complète du sujet

> **Objectif du projet :** introduction à Kubernetes via Vagrant, K3s, Ingress, K3d et Argo CD.  
> **Version du sujet :** 4.0  
> **Règle 42 :** un oubli = 0. Utilise cette checklist avant chaque rendu et avant la soutenance.

---

## Table des matières

1. [Contraintes générales](#contraintes-générales)
2. [Structure du dépôt (obligatoire)](#structure-du-dépôt-obligatoire)
3. [Partie 1 — K3s et Vagrant](#partie-1--k3s-et-vagrant)
4. [Partie 2 — K3s et trois applications](#partie-2--k3s-et-trois-applications)
5. [Partie 3 — K3d et Argo CD](#partie-3--k3d-et-argo-cd)
6. [Bonus — GitLab](#bonus--gitlab)
7. [Rendu et évaluation](#rendu-et-évaluation)
8. [Commandes de vérification rapide](#commandes-de-vérification-rapide)
9. [Pièges fréquents (0/100)](#pièges-fréquents-0100)

---

## Contraintes générales

- [ ] **Tout le projet se fait dans une machine virtuelle** (VM hôte). La soutenance se déroule sur l'ordinateur du groupe évalué.
- [ ] Les dossiers obligatoires sont à la **racine du dépôt Git** : `p1`, `p2`, `p3` (en **minuscules**).
- [ ] Dossier bonus optionnel : `bonus` (à la racine, en minuscules).
- [ ] Tu peux utiliser **n'importe quel outil** pour la VM hôte et **n'importe quel provider** Vagrant (VirtualBox, libvirt, etc.).
- [ ] Seul le travail **dans le dépôt** sera évalué — rien en dehors.
- [ ] Lire la documentation officielle K8s / K3s / K3d est attendu (le sujet ne couvre pas tout).

---

## Structure du dépôt (obligatoire)

```
.
├── p1/
│   ├── Vagrantfile
│   ├── scripts/          # scripts de provisionnement
│   └── confs/            # fichiers de configuration
├── p2/
│   ├── Vagrantfile
│   ├── scripts/
│   └── confs/
├── p3/
│   ├── scripts/
│   └── confs/
└── bonus/                # optionnel
    ├── Vagrantfile       # si nécessaire pour le bonus
    ├── scripts/
    └── confs/
```

### Règles de nommage des fichiers

- [ ] Tous les **scripts** → dossier `scripts/`
- [ ] Tous les **fichiers de configuration** (YAML, conf, etc.) → dossier `confs/`
- [ ] Noms des dossiers **exactement** `p1`, `p2`, `p3`, `bonus` (pas `P1`, `Part1`, etc.)

---

## Partie 1 — K3s et Vagrant

### Machines

- [ ] **2 machines virtuelles** gérées par Vagrant
- [ ] Distribution : **dernière version stable** de ton choix (Debian, Ubuntu, etc.)
- [ ] Ressources **minimales** (fortement conseillé par le sujet) :
  - [ ] **1 CPU** par machine
  - [ ] **512 Mo RAM** (ou 1024 Mo max) par machine

### Noms et réseau

| Machine | Hostname | IP fixe |
|---------|----------|---------|
| Server (controller) | `<login>S` (ex. `ael-youbS`) | `192.168.56.110` |
| ServerWorker (agent) | `<login>SW` (ex. `ael-youbSW`) | `192.168.56.111` |

- [ ] Les noms de machines = **login d'un membre de l'équipe**
- [ ] Hostname 1ère machine = login + **`S`** (Server)
- [ ] Hostname 2ème machine = login + **`SW`** (ServerWorker)
- [ ] IP **dédiée** sur l'interface réseau principale (réseau privé host-only typique VirtualBox)
- [ ] IP Server : **`192.168.56.110`**
- [ ] IP ServerWorker : **`192.168.56.111`**

### SSH

- [ ] Connexion SSH possible sur **les deux machines**
- [ ] SSH **sans mot de passe** (clés SSH configurées)

### Vagrantfile

- [ ] `p1/Vagrantfile` présent à la racine de `p1/`
- [ ] Vagrantfile conforme aux **pratiques modernes** (structure `config.vm.define`, provisions shell, etc.)
- [ ] Les machines se lancent avec `vagrant up` depuis `p1/`

### K3s

- [ ] **K3s installé sur les deux machines**
- [ ] Machine Server (`<login>S`) : K3s en mode **controller** (server)
- [ ] Machine ServerWorker (`<login>SW`) : K3s en mode **agent** (worker)
- [ ] L'agent rejoint bien le controller (cluster fonctionnel)

### kubectl

- [ ] **kubectl installé** (sur au moins la machine Server, idéalement utilisable depuis l'hôte)
- [ ] `kubectl get nodes` affiche **2 nodes** en état **Ready**

### Vérifications attendues en soutenance

- [ ] `ip a` (ou `ip a show <interface>`) — interfaces avec les bonnes IPs (noms modernes type `enp0s8`, pas forcément `eth0`)
- [ ] `kubectl get nodes` — 2 nodes Ready
- [ ] SSH sans mot de passe démontrable (`ssh vagrant@192.168.56.110` etc.)

---

## Partie 2 — K3s et trois applications

### Environnement

- [ ] **Une seule** machine virtuelle (pas deux comme en P1)
- [ ] Distribution : **dernière version stable**
- [ ] K3s installé en mode **server** (controller seul, pas besoin d'agent)
- [ ] Hostname de la machine : `<login>S` (ex. `ael-youbS`)
- [ ] IP de la machine : **`192.168.56.110`**

### Applications

- [ ] **3 applications web** de ton choix déployées dans K3s
- [ ] Chaque app affiche un contenu **distinct** (ex. texte "app1", "app2", "app3")

### Routage par Host header (Ingress)

Requêtes vers l'IP **`192.168.56.110`**, le contenu dépend du header **Host** :

| Host (header) | Application affichée |
|---------------|----------------------|
| `app1.com` | app1 |
| `app2.com` | app2 |
| *(autre / absent)* | app3 (**par défaut**) |

- [ ] `curl -H "Host: app1.com" http://192.168.56.110` → affiche **app1**
- [ ] `curl -H "Host: app2.com" http://192.168.56.110` → affiche **app2**
- [ ] `curl http://192.168.56.110` (sans Host ou autre Host) → affiche **app3**

### Replicas

- [ ] **Application 2** : **3 replicas** (Deployment avec `replicas: 3`)
- [ ] `kubectl get pods` confirme 3 pods pour app2

### Ingress

- [ ] Ressource **Ingress** configurée (obligatoire pour le routage Host)
- [ ] L'Ingress **n'apparaît pas** dans les screenshots du sujet **volontairement**
- [ ] Tu dois **montrer l'Ingress aux évaluateurs** pendant la soutenance (`kubectl get ingress`, `kubectl describe ingress`, etc.)

### Fichiers

- [ ] `p2/Vagrantfile` + `p2/scripts/` + `p2/confs/`
- [ ] Manifests K8s (Deployments, Services, Ingress) dans `confs/` ou déployés via scripts

---

## Partie 3 — K3d et Argo CD

### Environnement (sans Vagrant)

- [ ] **Pas de Vagrant** pour cette partie
- [ ] **K3d installé** sur la VM hôte
- [ ] **Docker installé** (requis par K3d)
- [ ] Comprendre et pouvoir expliquer la **différence K3s vs K3d** :
  - K3s = Kubernetes léger installé directement sur une machine
  - K3d = K3s exécuté **dans des conteneurs Docker** (clusters éphémères/multi-nœuds faciles)

### Script d'installation

- [ ] **Script d'installation** de tous les paquets/outils nécessaires (Docker, K3d, kubectl, etc.)
- [ ] Script dans `p3/scripts/`
- [ ] Tu dois pouvoir **l'exécuter pendant la soutenance** (réinstallation from scratch)

### Namespaces

- [ ] Namespace dédié à **Argo CD** (nom typique : `argocd`)
- [ ] Namespace **`dev`** contenant l'application déployée

```bash
kubectl get ns
# doit montrer au minimum : argocd, dev
```

### GitHub (obligatoire)

- [ ] **Dépôt GitHub public** avec les fichiers de configuration (manifests YAML)
- [ ] Le **login d'un membre du groupe** doit figurer dans le **nom du dépôt**
- [ ] Organisation libre du repo, mais les manifests doivent permettre le déploiement via Argo CD

### Argo CD (GitOps)

- [ ] Argo CD installé et fonctionnel
- [ ] Argo CD surveille le repo GitHub public
- [ ] L'application dans `dev` est **déployée automatiquement** par Argo CD depuis GitHub
- [ ] Interface Argo CD accessible (port-forward ou ingress) — montrable en soutenance

### Application (2 versions obligatoires)

**Option A — Application de Wil (recommandée pour débuter) :**

- [ ] Image : `wil42/playground`
- [ ] Docker Hub : https://hub.docker.com/r/wil42/playground
- [ ] Port : **8888**
- [ ] Tags : **`v1`** et **`v2`**

**Option B — Ta propre application :**

- [ ] Application codée par toi
- [ ] Image poussée sur un **dépôt Docker Hub public**
- [ ] Deux tags : **`v1`** et **`v2`**
- [ ] Les deux versions doivent avoir des **différences visibles** (ex. message JSON différent)

### Déploiement et changement de version

- [ ] `deployment.yaml` (ou équivalent) référence l'image avec le tag (`v1` ou `v2`)
- [ ] Pod running dans `dev` :

```bash
kubectl get pods -n dev
# NAME                          READY   STATUS    RESTARTS   AGE
# <app>-xxxxxxxxxx-xxxxx        1/1     Running   0          ...
```

- [ ] Test de version :

```bash
curl http://localhost:8888/
# v1 : {"status":"ok", "message": "v1"}
# v2 : {"status":"ok", "message": "v2"}
```

### Opération obligatoire en soutenance

Tu dois **live** pendant l'évaluation :

1. [ ] Modifier le tag dans `deployment.yaml` sur GitHub (`v1` → `v2` ou inverse)
2. [ ] `git add`, `git commit`, `git push`
3. [ ] Vérifier dans **Argo CD** que l'app est **synchronisée**
4. [ ] Vérifier avec `curl http://localhost:8888/` que la **nouvelle version** répond

Exemple du sujet :

```bash
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' deployment.yaml
git add . && git commit -m "v2" && git push
curl http://localhost:8888/
# {"status":"ok", "message": "v2"}
```

### Fichiers

- [ ] `p3/scripts/` — installation, création cluster K3d, install Argo CD
- [ ] `p3/confs/` — manifests locaux si besoin (Application Argo CD, etc.)
- [ ] Repo GitHub public lié (URL notée pour la soutenance)

---

## Bonus — GitLab

> ⚠️ **Le bonus n'est évalué que si la partie obligatoire est irréprochable** (100 % fonctionnelle, sans aucun problème). Sinon : bonus ignoré.

- [ ] Ajouter **GitLab** au labo de la Partie 3
- [ ] Version : **dernière version officielle** de GitLab
- [ ] GitLab tourne **en local**
- [ ] Namespace dédié : **`gitlab`**
- [ ] GitLab configuré pour fonctionner avec le cluster
- [ ] **Tout ce qui fonctionnait en Partie 3** doit fonctionner avec GitLab local (à la place ou en complément de GitHub — selon ton implémentation)
- [ ] Tu peux utiliser **Helm** ou tout autre outil nécessaire
- [ ] Dossier `bonus/` à la racine avec `scripts/`, `confs/`, et `Vagrantfile` si besoin

---

## Rendu et évaluation

### Avant de push

- [ ] Dossiers `p1`, `p2`, `p3` présents à la racine (minuscules)
- [ ] Chaque partie a ses `scripts/` et `confs/` si des scripts/configs existent
- [ ] Aucun secret (tokens, mots de passe) committé dans le repo
- [ ] Le dépôt GitHub public (P3) est accessible et à jour
- [ ] Double-check des **noms de fichiers et dossiers**

### Pendant la soutenance

- [ ] Démo sur **votre machine** (pas celle de l'évaluateur)
- [ ] Partie 1 : 2 VMs, SSH, kubectl get nodes
- [ ] Partie 2 : curl avec Host headers, 3 replicas app2, **montrer l'Ingress**
- [ ] Partie 3 : lancer le script d'install, montrer Argo CD, **changer la version live** via GitHub
- [ ] Savoir expliquer K3s vs K3d, Ingress, GitOps

---

## Commandes de vérification rapide

### Partie 1

```bash
cd p1 && vagrant up
vagrant ssh ael-youbS -c "ip a"
vagrant ssh ael-youbS -c "kubectl get nodes"
# 2 nodes Ready
ssh vagrant@192.168.56.110   # sans mot de passe
ssh vagrant@192.168.56.111   # sans mot de passe
```

### Partie 2

```bash
cd p2 && vagrant up
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110
kubectl get pods          # 3 pods pour app2
kubectl get ingress -A    # à montrer en soutenance
```

### Partie 3

```bash
# depuis p3/scripts/
./install.sh              # ou ton script
kubectl get ns            # argocd, dev
kubectl get pods -n argocd
kubectl get pods -n dev
curl http://localhost:8888/
# puis changement v1↔v2 via GitHub + vérif Argo CD
```

---

## Pièges fréquents (0/100)

| Erreur | Conséquence |
|--------|-------------|
| Dossiers `P1`/`P2`/`P3` au lieu de `p1`/`p2`/`p3` | Structure invalide |
| Mauvaises IPs (pas `192.168.56.110` / `.111`) | P1/P2 KO |
| SSH avec mot de passe | P1 KO |
| K3s agent ne rejoint pas le server | P1 KO |
| Pas d'Ingress ou routage Host incorrect | P2 KO |
| App2 sans 3 replicas | P2 KO |
| Oublier de montrer l'Ingress en soutenance | P2 KO |
| Pas de repo GitHub **public** | P3 KO |
| Login absent du **nom** du repo GitHub | P3 KO |
| Argo CD ne sync pas depuis GitHub | P3 KO |
| Impossible de changer v1→v2 live | P3 KO |
| Pas de script d'installation P3 | P3 KO |
| Partie 3 avec Vagrant | Hors sujet |
| Bonus sans mandatory parfaite | Bonus non évalué |

---

## Progression recommandée

1. **p1** — Vagrant + K3s 2 nœuds (fondations)
2. **p2** — Ingress + 3 apps (Kubernetes workloads)
3. **p3** — K3d + Argo CD + GitOps (CI/CD)
4. **bonus** — GitLab (seulement si tout le mandatory est stable)

---

## Ressources utiles

- [K3s documentation](https://docs.k3s.io/)
- [K3d documentation](https://k3d.io/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Argo CD](https://argo-cd.readthedocs.io/)
- [Vagrant](https://developer.hashicorp.com/vagrant/docs)
- [wil42/playground (Docker Hub)](https://hub.docker.com/r/wil42/playground)

---

*Checklist générée à partir du sujet IoT v4.0 (`en.subject.pdf`). Coche chaque item avant rendu et avant soutenance.*
