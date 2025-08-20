Pour utiliser SyncState, vous devrez d'abord configurer les fonctionnalités et les autorisations iCloud dans votre projet Xcode. Voici une introduction pour vous guider tout au long du processus :

### Configuration des fonctionnalités iCloud :

1. Ouvrez votre projet Xcode et ajustez les identifiants de lot pour les cibles macOS et iOS afin qu'ils correspondent aux vôtres.
2. Ensuite, vous devez ajouter la fonctionnalité iCloud à votre projet. Pour ce faire, sélectionnez votre projet dans le navigateur de projets, puis sélectionnez votre cible. Dans la barre d'onglets en haut de la zone de l'éditeur, cliquez sur « Capacités ».
3. Dans le volet Capacités, activez iCloud en cliquant sur le commutateur de la ligne iCloud. Vous devriez voir le commutateur passer en position Activé.
4. Une fois que vous avez activé iCloud, vous devez activer le stockage clé-valeur. Vous pouvez le faire en cochant la case « Stockage clé-valeur ».

### Mise à jour des autorisations :

1. Vous devrez maintenant mettre à jour votre fichier d'autorisations. Ouvrez le fichier d'autorisations de votre cible.
2. Assurez-vous que la valeur du magasin clé-valeur iCloud correspond à votre ID de magasin clé-valeur unique. Votre ID unique doit respecter le format `$(TeamIdentifierPrefix)<votre ID de magasin clé-valeur>`. La valeur par défaut doit être quelque chose comme `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`. C'est très bien pour les applications à plate-forme unique, mais si votre application se trouve sur plusieurs systèmes d'exploitation Apple, il est important que les parties de l'ID du magasin clé-valeur soient les mêmes pour les deux cibles.

### Configuration des appareils :

En plus de configurer le projet lui-même, vous devez également préparer les appareils qui exécuteront le projet.

- Assurez-vous qu'iCloud Drive est activé sur les appareils iOS et macOS.
- Connectez-vous aux deux appareils avec le même compte iCloud.

Si vous avez des questions ou rencontrez des problèmes, n'hésitez pas à nous contacter ou à soumettre un problème.
