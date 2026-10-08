# Configuration d'une infrastructure Proxmox

## Informations de développement

La base commune est développée et maintenue par **Baptiste Lavogiez** et **Jonas Facon**, avec pour objectif de proposer une infrastructure serveur fiable, automatisée et reproductible autour de Proxmox VE.

Notre projet commun a vocation à être la source commune de nos infrastructures Proxmox personnelles (templates, outils d'administration type VPN...). Puisqu'ayant chacun un serveur avec des besoins et services différents, ce dépôt est forké par chacun.

Puisque le dépôt doit être public, et pour que les workflows le soient aussi, nous restons sur GitHub par simplicité. 

**Pour des raisons de sécurité vis-à-vis des runners auto-hébergés, les dépôts fork n'autorisent pas de PR (un run non autorisé pourrait être une introduction sur le réseau privé au PVE). Pour faire une PR en n'étant pas membre, il faut la faire sur le dépôt commun (il n'a aucun runner privé rattaché).** 

Ce projet privilégie une approche Infrastructure as Code et similaire aux principes GitOps.

### Réalisé par

| Auteur            | Email                                                             | GitHub                                                           |
| ----------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------- |
| Baptiste Lavogiez | [baptiste.lavogiez@proton.me](mailto:baptiste.lavogiez@proton.me) | [blavogiez](https://github.com/blavogiez) |
| Jonas Facon       | [jonas.facon@proton.me](mailto:jonas.facon@proton.me)             | [Jonas0o0](https://github.com/Jonas0o0)   |

## Présentation

L’objectif de ce projet est de concevoir un serveur Proxmox VE clé en main.
Il est pensé pour fournir une base solide regroupant les services essentiels dont tout serveur a besoin, comme un VPN, un reverse proxy, ainsi qu’une configuration sécurisée et fiable.
Cela inclut notamment le chiffrement des disques, les sauvegardes automatiques et la gestion de réseaux virtuels.

Pour plus de détails sur l'architecture réseau et les composants, consultez la **[Documentation de l'Infrastructure](docs/INFRA.md)**.

## Conventions de développement

Puisqu'il s'agit d'un projet commun, nous définissons ces conventions :
- Limiter le développement par IA afin d'apprendre au mieux, n'utiliser que pour se documenter / review
- Lorsque l'on utilise un nouvel outil, se renseigner rapidement sur les bonnes pratiques
- Appliquer les principes [DRY, KISS, YAGNI](https://scalastic.io/solid-dry-kiss/)
- [Feature branch](https://www.atlassian.com/fr/git/tutorials/comparing-workflows/feature-branch-workflow) et merge requests (à part pour des petits edit / modifications de doc)
- Pour les installations complexes, écrire une documentation / procédure pour que l'autre puisse la reproduire

## Approche GitOps & auto-déploiement

Le projet repose sur une approche GitOps : le dépôt Git constitue la source de vérité de l’infrastructure.

Ainsi, chaque modification validée sur la branche `main` déclenche automatiquement la mise à jour des serveurs, garantissant une configuration cohérente, versionnée et reproductible.

Pour résumer rapidement, les déploiements des services d'administration sont réalisés par playbooks, avec un playbook Ansible pouvant assurer le déploiement de n'importe quel service en argument (grâce à l'arborescence du dépôt avec une logique uniforme). En CI/CD, nous itérons donc sur tous les services déployables et appelons ce playbook.

Ce playbook va :
- charger les configurations et secrets déchiffrés depuis `settings.enc.yml` via SOPS ;
- copier la stack vers l'hôte cible (VM ou LXC) ;
- injecter les variables et secrets dans les templates Jinja2 ;
- relancer la stack Docker Compose si des fichiers ont changé.

### Optimisation

Nous utilisons une [action réutilisable](https://github.com/tj-actions/changed-files) qui détecte si un fichier du service a changé dans le dernier commit (configuration conteneur / fichier monté). Ainsi, seuls les services qui ont changé (= ayant besoin d'être redéployés) sont redéployés. C'est dans notre cas plus rapide et optimisé que de faire le playbook ansible sur tous les hôtes car nos services changent rarement, et dans le cas d'une "vérification de changement" uniquement par Ansible on perdrait le temps à contacter tous les hôtes, alors qu'en réalité on peut savoir qui a besoin d'être redéployé avec le dernier commit.

Côté GitHub Actions, le système de matrix permet de paralléliser un job sur lequel est itéré une liste, en l'occurrence les services (obtenus par [cette action réutilisable](github.com/philips-labs/list-folder-action))

Ces mises à jour sont appliquées sur les dépôts forks. En voici un exemple (déclenchement manuel, avec tout de déployé) : 
<img width="1198" height="596" alt="image" src="https://github.com/user-attachments/assets/1bae44da-15ec-4ae2-846d-1de670e07528" />

[Run correspondant](https://github.com/blavogiez-org/proxmox-configuration/actions/runs/28758799580)
