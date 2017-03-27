        alldock=($(docker ps -a -q));
        for i in "${!alldock[@]}"; do
          echo ${alldock[$i]} $i;
          docker stop ${alldock[$i]};
          docker rm ${alldock[$i]};
        done


        allimages=($(docker images -q));
        for i in "${!allimages[@]}"; do
          echo ${allimages[$i]} $i;
          docker rmi ${allimages[$i]};
        done

