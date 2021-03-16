  # Draft cmd
  idgn=$(docker ps | grep geonature | awk '{print $1}'); docker exec -it ${idgn} /bin/bash

