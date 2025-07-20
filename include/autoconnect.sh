if [[ -n "${OUTPUT[@]:1}" ]]; then
    for i in "${OUTPUT[@]:1}"; do
        read NAME ZONE MACHINE_TYPE PREEMPTIBLE \
             INTERNAL_IP EXTERNAL_IP STATUS <<< $i
    done

    if [[ -n "$EXTERNAL_IP" ]]; then
        # fix empty PREEMPTIBLE field
        if [[ $EXTERNAL_IP == "RUNNING" ]]; then
            EXTERNAL_IP=$INTERNAL_IP
        fi

        # delete old SSH keys
        #ssh-keygen -q -F ${EXTERNAL_IP} && ssh-keygen -q -R ${EXTERNAL_IP}

        printf "Connecting to $NAME ($EXTERNAL_IP)."
        until ( nc -n -z -w 10 $EXTERNAL_IP 22 ); do
            printf "."
            sleep 0.5
        done
        printf "\n"

        #exec ssh -i ~/.ssh/id_rsa_gcp -o StrictHostKeyChecking=no $EXTERNAL_IP
        exec ssh $EXTERNAL_IP
    fi
fi
