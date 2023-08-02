#!/bin/bash
# To continue with the tests we must logged into the exium-client using the workspace name and username
i=1
current_username=$(whoami)
mkdir -p /home/${current_username}/ocn_automation
rm -f -R /home/${current_username}/ocn_automation/*
slackrawdnsfile=/home/${current_username}/ocn_automation/slackrawdns
slackrawspafile=/home/${current_username}/ocn_automation/slackrawspa
detailedlogfile=/home/${current_username}/ocn_automation/detailed_log
rawconnectionstatusfile=/home/${current_username}/ocn_automation/rawconnectionstatus
pingspafile=/home/${current_username}/ocn_automation/pingspa
pingdnsfile=/home/${current_username}/ocn_automation/pingdns
internetconnectionfile=/home/${current_username}/ocn_automation/internetconnectionstatus
resulterrorfile=/home/${current_username}/ocn_automation/resulterror
finalresultfile=/home/${current_username}/ocn_automation/finalresult

#check if the user is logged In
    loginstatus=$(exium-cli status | grep -i Permission  | cut -d "." -f 2 | sed 's/ //g')
    if [[ $loginstatus == "UsernotLoggedin" ]]; then
        echo 'User not Logged in. Please login using "exium-cli login -w <workspace> -u <username>"'
        echo "Please try again after loggin In...Bye"
        echo " $(whoami) - $(date) - Script Execution Failed - User not Logged in. Please login using exium-cli login -w <workspace> -u <username>" > $resulterrorfile
        python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
        echo "-Result Error Message Sent..."
        exit
    fi

#exium_error fucntion is called to check the exium-client availability
exium_error ()
{
    
    exiumerror=$(exium-cli status | grep -e Connecting -e Active -e NotActive -e Disconnecting -e Fatal | cut -d ":" -f 2 | sed 's/ //g')

    if [ $exiumerror == 'Fatal error : listen udp4 :9384: bind: address already in use' ]
    then
    errorflag=1
    elif [ -z "$exiumerror" ]
    then
    errorflag=2
    else
    #NotActive flag
    errorflag=0
    fi


    if [ $errorflag -eq 1 ]
    then 
        echo "Fatal error : listen udp4 :9384: bind: address already in use"
        echo "Restarting Exium-Client-Service - Please wait for 30 Seconds"
        sudo killall -s SIGKILL exium-cli
        if [ $? -eq 0 ]
                then
                    echo "Exium.Client-Service Successfully Restarted"
                    sleep 30
                elif [ $? -eq 1 ]
                then
                    echo "No Process Found - OK"
                else
                    echo "Exium-Client Restart Failed"
                    echo "Aborting Script Execution - Please try to reset client manually"
                    echo "-------------------- Script Terminated --------------------"
                    echo " $(whoami) - $(date) - Script Execution Failed - Fatal error udp4 :9384 - Exium.Client.service restart failed - manual restart required:exclamation:" > $resulterrorfile
                    python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
                    echo "-Result Error Message Sent..."
                    exit
        fi
    fi

                
    if [ $errorflag -eq 2 ]; then
    echo "Fatal error : service not running"
    echo "Trying to restart the exium-client - Please wait 30 Seconds"
    sudo service exium-client restart
        if [ $? -eq 0 ]
            then
                echo "Exium.Client Successfully Restarted"
                sleep 30
            else
                echo "Service exium-client restart - Failed"
                echo "Trying to restart exium-client - systemctl"
                sudo systemctl restart exium-client.service
                 if [ $? -eq 0 ]
                 then
                     echo "systemctl restart exium-client.service - Success"
                     sleep 30
                 else
                     echo "systemctl restart exium-client.service - Failed"
                     echo "Aborting Script Execution - Please try to reset client manually"
                     echo "-------------------- Script Terminated --------------------"
                     echo " $(whoami) - $(date) - Script Execution Failed - Fatal error : service not running - Exium.Client restart failed - manual restart required:exclamation:" > $resulterrorfile
                     python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
                     echo "-Result Error Message Sent..."
                     exit
                 fi
        fi
      
    fi

    if [ $errorflag -eq 0 ]
    then
        pid=$(pidof exium-cli)
        if [ -n "$pid" ];
        then
        echo "Found running jobs for exium-cli - PID : $pid"
        sudo killall -s SIGKILL exium-cli
        echo "Waiting for $pid to DIE :)"
        sleep 10
        echo "$pid died - RIP :( - please wait 30 seconds"
        sleep 30
        exium-cli disconnect
        fi
    fi                
}


exium_error
exium_error
exium_error

if [ $# -eq 0 ];
then
    exium-cli servers  | awk 'NF{NF-=1};1' | sed 1d > /home/${current_username}/ocn_automation/servername
    exium-cli servers  | awk '{print $NF}' | sed 1d > /home/${current_username}/ocn_automation/servers
elif [ $1 == "-A" ];
    then
    exium-cli servers stage | awk 'NF{NF-=1};1' | sed 1d > /home/${current_username}/ocn_automation/servername
    exium-cli servers stage | awk '{print $NF}' | sed 1d > /home/${current_username}/ocn_automation/servers   
else
    echo "run the script without any arguments for checking Production environmet Cyber-Node Status"
    echo "./status -A for checking status of all Cyber-Node in Production and Stage Environment"
    exit
fi
#functions

client_restart ()
{
    echo "Trying to restart the exium-client - Please wait 60 Seconds" | tee -a $detailedlogfile
    sudo service exium-client restart
    if [ $? -eq 0 ]
    then
        echo "service exium-client restart - Success " | tee -a $detailedlogfile
        echo >> $detailedlogfile
        sleep 30
    else
        echo "Service exium-client restart - Failed" | tee -a $detailedlogfile
        echo "Trying to restart exium-client - systemctl" | tee -a $detailedlogfile
        sudo systemctl restart exium-client.service
        if [ $? -eq 0 ]
        then
            echo "systemctl restart exium-client.service - Success" | tee -a $detailedlogfile
            sleep 30
        else
            echo "systemctl restart exium-client.service - Failed" | tee -a $detailedlogfile
            echo "Aborting Script Execution - Please try to reset client manually" | tee -a $detailedlogfile
            echo "-------------------- Script Terminated --------------------" | tee -a $detailedlogfile
            echo " $(whoami) - $(date) - Script Execution Failed - Fatal error : service not running - Exium.Client restart failed - manual restart required:exclamation:" > $resulterrorfile
            python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
            echo "-Result Error Message Sent..."
            exit
        fi
            
    fi            
}

exium_cli_killer ()
{
    echo "Restarting Exium-Client-Service - Please wait for 30 Seconds" | tee -a $detailedlogfile
    sudo killall -s SIGKILL exium-cli
    if [ $? -eq 0 ]
    then
        echo "Exium.Client-Service Successfully Restarted" | tee -a $detailedlogfile
        echo >> $detailedlogfile
        sleep 30
    elif [ $? -eq 1 ]
    then
        echo "No Process Found - OK"
    else
        echo "Exium-Client Restart Failed" | tee -a $detailedlogfile
        echo "Aborting Script Execution - Please try to reset client manually" | tee -a $detailedlogfile
        echo "-------------------- Script Terminated --------------------" | tee -a $detailedlogfile
        echo "Script Execution Failed - Fatal error udp4 :9384 - Exium.Client.service restart failed [10 Failures] - manual restart required" | tee -a $detailedlogfile
        echo " $(whoami) - $(date) - Script Execution Failed - Fatal error udp4 :9384 - Exium.Client.service restart failed [10 Failures] - manual restart required:exclamation:" > $resulterrorfile
        python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
        echo "-Result Error Message Sent..."
        exit
    fi        
}

connection_status_check () 
{
# check current connection status of the client
fatalerrorcount=0
connectingcount=0
disconnectingcount=0

    connectionstatusocn=$(exium-cli status | grep -e Connecting -e Active -e NotActive -e Disconnecting -e Fatal | cut -d ":" -f 2 | sed 's/ //g')
    if [ $connectionstatusocn == 'Active' ]
    then
    connectionflagocn=1
    elif [ $connectionstatusocn == 'Connecting' ]
    then
    connectionflagocn=2
    elif [ $connectionstatusocn == 'Disconnecting' ]
    then
    connectionflagocn=3
    elif [ $connectionstatusocn == 'Fatal error : listen udp4 :9384: bind: address already in use' ]
    then
    connectionflagocn=4
    elif [ -z "$connectionstatusocn" ]
    then
    connectionflagocn=5
    else
    #NotActive flag
    connectionflagocn=0
    fi
    if [ $connectionflagocn -eq 2 ] || [ $connectionflagocn -eq 3 ] || [ $connectionflagocn -eq 4 ] || [ $connectionflagocn -eq 5 ]  || [ $connectionflagocn -eq 0 ]
        then 
            while [ $connectionflagocn -eq 2 ] || [ $connectionflagocn -eq 3 ] || [ $connectionflagocn -eq 4 ] || [ $connectionflagocn -eq 5 ]  || [ $connectionflagocn -eq 0 ]
                do
                sleep 5
                connectionstatusocn=$(exium-cli status | grep -e Connecting -e Active -e NotActive -e Disconnecting -e Fatal | cut -d ":" -f 2 | sed 's/ //g')

                if [ $connectionstatusocn == 'Active' ]
                then
                connectionflagocn=1
                elif [ $connectionstatusocn == 'Connecting' ]
                then
                connectionflagocn=2
                connectingcount=$((connectingcount+1))
                elif [ $connectionstatusocn == 'Disconnecting' ]
                then
                disconnectingcount=$((disconnectingcount+1))
                connectionflagocn=3
                elif [ $connectionstatusocn == 'Fatal error : listen udp4 :9384: bind: address already in use' ]
                then
                connectionflagocn=4
                fatalerrorcount=$((fatalerrorcount+1))
                elif [ -z "$connectionstatusocn" ]
                then
                connectionflagocn=5
                else
                #NotActive flag
                connectionflagocn=0
                fi
                
               if [ $connectionflagocn -eq 0 ]
                then
                    pid=$(pidof exium-cli)
                    if [ -n "$pid" ];
                    then
                        exium_cli_killer
                    else
                        connectionflagocn=1
                    fi
                fi

                 if [ $connectionflagocn -eq 2 ]
                 then
                    echo "Still in connecting phase....." | tee -a $detailedlogfile
                    if [ $connectingcount -ge 20 ]
                    then
                    echo "Client is looping in connecting phase" | tee -a $detailedlogfile
                    exium_cli_killer
                    client_restart
                    fi
                    sleep 3
                 fi

                 if [ $connectionflagocn -eq 3 ]
                 then 
                    echo "Still in Disconnecting phase....." | tee -a $detailedlogfile

                    if [ $disconnectingcount -ge 20 ]
                    then
                    echo "Client is looping in Disconnecting phase" | tee -a $detailedlogfile
                    exium_cli_killer
                    client_restart
                    fi
                    sleep 3
                 fi

                 if [ $connectionflagocn -eq 4 ]
                 then 
                    echo "Fatal error : listen udp4 :9384: bind: address already in use" | tee -a $detailedlogfile
                    if [ $fatalerrorcount -ge 2 ]
                    then
                        exium_cli_killer
                    fi
                    sleep 3
                 fi

                 if [ $connectionflagocn -eq 5 ]
                    then
                    echo "Fatal error : service not running" | tee -a $detailedlogfile
                    client_restart
                fi

                done
                fatalerrorcount=0
                connectingcount=0
                disconnectingcount=0
                sleep 2
                connectionstatusocn=$(exium-cli status | grep Active | cut -d ":" -f 2 | sed 's/ //g')
                if [ $connectionstatusocn == 'Active' ]
                then
                connectionflagocn=1
                else 
                connectionflagocn=0
                fi
    fi
}

connection_status_check_after_disconnect () 
{
    fatalerrorcount=0
    connectingcount=0
    disconnectingcount=0
    activecount=0
# check current connection status of the client
    connectionstatusocn=$(exium-cli status | grep -e Connecting -e Active -e NotActive -e Disconnecting -e Fatal | cut -d ":" -f 2 | sed 's/ //g')
    if [ $connectionstatusocn == 'Active' ]
    then
    connectionflagocn=1
    elif [ $connectionstatusocn == 'Connecting' ]
    then
    connectionflagocn=2
    elif [ $connectionstatusocn == 'Disconnecting' ]
    then
    connectionflagocn=3
    elif [ $connectionstatusocn == 'Fatal error : listen udp4 :9384: bind: address already in use' ]
    then
    connectionflagocn=4
    elif [ -z "$connectionstatusocn" ]
    then
    connectionflagocn=5
    else
    #NotActive flag
    connectionflagocn=0
    fi
    if [ $connectionflagocn -eq 1 ] || [ $connectionflagocn -eq 2 ] || [ $connectionflagocn -eq 3 ] || [ $connectionflagocn -eq 4 ] || [ $connectionflagocn -eq 5 ]
        then 
            while [ $connectionflagocn -eq 1 ] || [ $connectionflagocn -eq 2 ] || [ $connectionflagocn -eq 3 ] || [ $connectionflagocn -eq 4 ] || [ $connectionflagocn -eq 5 ]
                do
                sleep 5
                connectionstatusocn=$(exium-cli status | grep -e Connecting -e Active -e NotActive -e Disconnecting -e Fatal | cut -d ":" -f 2 | sed 's/ //g')
                   
                if [ $connectionstatusocn == 'Active' ]
                then
                connectionflagocn=1
                activecount=$((activecount+1))
                elif [ $connectionstatusocn == 'Connecting' ]
                then
                connectionflagocn=2
                connectingcount=$((connectingcount+1))
                elif [ $connectionstatusocn == 'Disconnecting' ]
                then
                connectionflagocn=3
                disconnectingcount=$((disconnectingcount+1))
                elif [ $connectionstatusocn == 'Fatal error : listen udp4 :9384: bind: address already in use' ]
                then
                connectionflagocn=4
                fatalerrorcount=$((fatalerrorcount+1))
                elif [ -z "$connectionstatusocn" ]
                then
                connectionflagocn=5
                else
                #NotActive flag
                connectionflagocn=0
                fi
                
                 if [ $connectionflagocn -eq 1 ]
                 then
                    echo "Still in Active State....." | tee -a $detailedlogfile
                    if [ $activecount -ge 5 ]
                    then
                        exium_cli_killer
                        client_restart
                    fi
                    exium-cli disconnect
                    sleep 3
                 fi

                 if [ $connectionflagocn -eq 2 ]
                 then
                    echo "Still in connecting phase....." | tee -a $detailedlogfile
                    if [ $connectingcount -ge 20 ]
                    then
                    echo "Client is looping in connecting phase" | tee -a $detailedlogfile
                    exium_cli_killer
                    client_restart
                    fi
                    sleep 3
                 fi
                 
                 if [ $connectionflagocn -eq 3 ]
                 then
                    echo "Still in Disconnecting phase....." | tee -a $detailedlogfile
                    if [ $disconnectingcount -ge 20 ]
                    then
                    echo "Client is looping in Disconnecting phase" | tee -a $detailedlogfile
                    exium_cli_killer
                    client_restart
                    fi
                    sleep 3
                 fi

                 if [ $connectionflagocn -eq 4 ]
                    then 
                    echo "Fatal error : listen udp4 :9384: bind: address already in use" | tee -a $detailedlogfile
                    if [ $fatalerrorcount -ge 2 ]
                    then
                        exium_cli_killer
                        client_restart
                    fi
                    sleep 3
                 fi
                 if [ $connectionflagocn -eq 5 ]
                    then
                    echo "Fatal error : service not running" | tee -a $detailedlogfile
                    client_restart
                fi
                done
                fatalerrorcount=0
                connectingcount=0
                disconnectingcount=0
                
    fi
}



ping_dns () 
{
     ping -c 10 100.100.100.100 > $pingdnsfile
        cat $pingdnsfile | tee -a $detailedlogfile > /dev/null
        echo "$line - $currentservername" >> $slackrawdnsfile
        cat $pingdnsfile | tail -n 2 | head -n1 >> $slackrawdnsfile
        echo >> $slackrawdnsfile
        echo >> $detailedlogfile
        sleep 3
}

ping_spa ()
{
    ping -c 10 10.0.0.5 > $pingspafile
        cat $pingspafile | tee -a $detailedlogfile > /dev/null
        echo "$line - $currentservername" >> $slackrawspafile
        cat $pingspafile | tail -n 2 | head -n1 >> $slackrawspafile
        echo >> $detailedlogfile
        echo >> $slackrawspafile
        sleep 3
}

internet_check ()
{
     wget -q --spider http://www.google.com
        if [ $? -eq 0 ]; then
            echo "---------------Internet Connection Successfull - $line [$currentservername] ---------------"
            echo "---------------Internet is Accessible - $line [$currentservername] ---------------" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Internet is Accessible - $line - $currentservername" >> $internetconnectionfile 
        else
            echo "---------------Internet Connection Failed - $line [$currentservername] ---------------"
            echo "---------------Not able to access Internet - $line [$currentservername] ---------------" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Internet is Not Accessible - $line - [$currentservername]" >> $internetconnectionfile
        fi
}


# Internet access check
wget -q --spider http://www.google.com
if [ $? -eq 1 ];  
then  
echo "-No Internet Connection is Available.!!!"
echo "-----Terminating OCN-Status-Check-----"
echo "No Internet Connection is Available"  >> $slackmessagefile
echo "Terminating OCN-Status-Check" >> $slackmessagefile
exit
fi    


# display the available server list
echo "----------Available Servers------------------------------"
exium-cli servers
echo "---------------------------------------------------------"
# check current connection status of the client

exium-cli disconnect
connection_status_check_after_disconnect

now=$(date)
# OCN-Automation starts from here
echo
echo "---------------Starting OCN-Automation - $now---------------"
echo "use -A flag for checking status of all Cyber-Nodes"
echo
echo "---------------Starting OCN-Automation - $now---------------" >> $detailedlogfile
echo >> $detailedlogfile
echo "SPA - [10.0.0.5] Ping Results" >> $slackrawspafile
echo >> $slackrawspafile
echo "DNS - [100.100.100.100] Ping Results" >> $slackrawdnsfile
echo >> $slackrawdnsfile
echo "Internet - [www.google.com] Results" >> $internetconnectionfile
echo >> $internetconnectionfile
echo "---------- $(whoami) - $(date) ----------" >> $rawconnectionstatusfile
echo >> $rawconnectionstatusfile
serverfile=/home/${current_username}/ocn_automation/servers
servernamefile=/home/${current_username}/ocn_automation/servername
filename=$serverfile
CNcount=$(wc -l $serverfile | awk '{print $1}' | sed -n $i'p')
echo >> $detailedlogfile
echo
echo "Total Cyber-Node Listed : $CNcount" | tee -a $detailedlogfile
echo
echo >> $detailedlogfile
while read line; do
    sleep 5
    echo
    currentservername=$(cat $servernamefile | awk '{print $1,$2}' | sed -n $i'p')
    # connect to the corresponding ocn
    echo "---------------Connecting to OCN $line [$currentservername] ---------------"
    echo "--------------- Connecting to $line [$currentservername] ---------------" >> $detailedlogfile
    exium-cli connect -s $line
    sleep 5
    connection_status_check
    if [ $connectionflagocn -eq 1 ];
        then
        echo "+Successfully connected to $line [$currentservername] ..."
        echo "--------------- Successfully Connected - $line [$currentservername] ---------------" >> $detailedlogfile
        echo "Connection Successfull - $line [$currentservername]" >> $rawconnectionstatusfile
        # pinging DNS 100.100.100.100
        echo "---------------Ping Result For DNS - $line [$currentservername] ---------------" >> $detailedlogfile
        ping_dns
        # pinging SPA 10.0.0.5
        ping_spa
        # Checking Internet connection
        internet_check
        exium-cli disconnect
        connection_status_check_after_disconnect
    else 
        echo "---------------Failed to connect - $line [$currentservername] ---------------"
        echo "---------------Failed to Connect - $line [$currentservername] ---------------" >> $detailedlogfile
        echo "Connection Failed - $line [$currentservername]" >> $rawconnectionstatusfile
        # connect to the same ocn for the second time
        echo "+Connecting to OCN $line [$currentservername] ---[Second Time]---"
        exium-cli connect -s $line
        sleep 5
        connection_status_check
        
        if [ $connectionflagocn -eq 1 ];
            then
            echo
            echo "+Successfully Connected - $line [$currentservername] ---[Second Time]---"
            echo "+Successfully Connected - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
            echo "Connection Successfull - $line [$currentservername] - [Second Time]" >> $rawconnectionstatusfile

            # pinging DNS 100.100.100.100
            echo "---------------Ping Result For DNS - $line [$currentservername] ---[Second Time]------------------" >> $detailedlogfile
            ping_dns
            # pinging SPA 10.0.0.5
            echo "---------------Ping Result For SPA - $line [$currentservername] ---[Second Time]------------------" >> $detailedlogfile
            ping_spa
            # Checking Internet connection
            echo "+Checking Internet Connection ---[Second Time]---"
            internet_check
            exium-cli disconnect
            connection_status_check_after_disconnect
        else 
            echo "-Failed to Connect - $line [$currentservername] ---[Second Time]---"
            echo "Failed to Connect - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Connection Failed - $line [$currentservername]" >> $rawconnectionstatusfile
        fi
    fi
i=$((i+1))   
done < $filename
exium-cli disconnect > /dev/null
echo
echo "---------------OCN Automation Finished---------------"
echo >> $detailedlogfile
echo "---------------OCN Automation Finished---------------" >> $detailedlogfile


result_count=$(cat $rawconnectionstatusfile | wc -l)
if [ $result_count -ge 3 ]
    then
        servercount=$((i-1))
        echo >> $rawconnectionstatusfile
        echo "Total Cyber-Node Listed : $servercount" >> $rawconnectionstatusfile
        #report generation starts from here
        #success messages 
        echo >> $rawconnectionstatusfile
        echo >> $slackrawdnsfile
        echo >> $slackrawspafile
        echo >> $internetconnectionfile
        cat $rawconnectionstatusfile $slackrawdnsfile $slackrawspafile $internetconnectionfile > $finalresultfile
        python3 /home/${current_username}/OCN-Status-Automation/send_finalresult.py
        exit
else
    #sending error message slack channel exedge-monitoring-results
    echo " $(whoami) - $(date) - Script Execution Failed:exclamation:" >> $resulterrorfile
    python3 /home/${current_username}/OCN-Status-Automation/slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/resulterror`"
    echo "-Result Error Message Sent..."
    exit
fi

