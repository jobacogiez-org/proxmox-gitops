# Script d'initialisation de l'infrastructure

Ce dossier contient le script nécessaire pour configurer votre environnement lors de la **toute première installation** de l'infrastructure. 

Leur rôle est de préparer vos variables (domaines, identifiants Proxmox, paramètres GitHub) de façon interactive, de générer votre clé de chiffrement SOPS et de chiffrer vos fichiers de configuration sensibles de façon automatisée avant même de les écrire sur le disque.

### Script disponible

- `init.sh` : C'est le script principal. Il orchestre l'ensemble du processus d'initialisation. Il vérifie les dépendances, configure les hooks Git, met en place SOPS/AGE, et chiffre directement `settings.source.yml` pour vous permettre de configurer `settings.enc.yml`. Enfin, il s'assure que les variables Terraform sont générées et chiffrées correctement. **C'est le seul script que vous avez besoin de lancer.**

### Utilisation au quotidien

Ce script ne sert **qu'une seule fois** pour initialiser tout le projet. 

Une fois l'initialisation terminée, vous n'aurez plus jamais à utiliser les scripts de ce dossier. La gestion quotidienne de votre infrastructure, les mises à jour et les déploiements se feront exclusivement via le `Makefile` à la racine du projet.

👉 **[Consulter le Makefile](../Makefile)**