#Etape 1:
Lancer le conteneur Docker. Pour cela, vous devez avoir Docker et Docker Compose installés (docker --version et docker compose --version pour vérifier). Ensuite, lancez le fichier de script situé dans le répertoire db. Ce fichier de script lancera le conteneur automatiquement. Il y a un fichier .bat si vous utilisez Windows et un fichier .sh si vous utilisez Linux.

#Etape 2:
Lancer le fichier de script Python situé à la racine du projet. Il se peut que vous deviez installer des dépendances via pip. Ce processus peut prendre beaucoup de temps.

## Désormais, tout est initialisé et vous pouvez lancer les commandes suivantes pour entrer des commandes dans la base de données : 
 # Pour vous connecter via les lignes de commandes au conteneur docker
 docker exec -it postgres /bin/bash

 # Pour lancer le terminal pour postgres
  psql -U API_ADMIN -d DATA_BASE_API
