#<sitename>
#----------
#set -x
if [[ $# -eq 1 &&  ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    echo "
        This $0 script checkes the build of the all sites
        if there is no particualr site is given as argument.
        It is assumed that HCIROOT environment variable has 
        been set to parent of site/s directory. 
        Limitation is that to check multiple sites, you have to 
        quote site separated by space. 

        usage: $0 without any arguments, will check all sites
               $0 with <icc_fhir> will check only icc_fhir site
               $0 \"icc_main icc_fhir icc_edge\" will check for three sites

            "
        exit
fi
sites=""
if [ $# -eq 1 ];then
    for site in $1 ; 
    do
        sites=${sites}"  "${HCIROOT}/${site}
    done
fi

#----------
#get all sites 
if  [ "$sites" == '' ]; then
    sites=$(ls ${HCIROOT}/*/NetConfig |grep -Eiv "sample|siteproto|template"|sed 's/\/NetConfig//')  2>/dev/null
fi
failure_count=0

#<build_report>
#---------------
log=/tmp/build_verification.log
html_file=/tmp/build_verification.html
html=0
echo "<!DOCTYPE html>
<html> 
<head>
<style>
table {
font-family: Arial, Helvetica, Sans-serif;
border-collapse: collapse;
width: 100%
} 
td, th {
    border: 1px solid #ddd
    text-aligh:center
    padding: 8px;
} 
tr:nth-child(even) {background-color:#f2f2f2;} 
tr:hover {background-color: #ddd;} 
th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-aligh: center;
    background-color: #04AA6D;
    color: white;
} 
b {
    color:red;
} 
</style>
</head>
<body>
<table id=\"hci\"> <tr><th>Site</th><th>Process/Protocol/File</th><th>Comment</th></tr>" >${html_file} 
echo "<tr><td></td><td> Please see log file for details:<a href=\"${log}\">Log file </a></td><td/></tr>" >>${html_file}   

echo "${LINENO} Started process $0 at `date` on `hostname`" > ${log} 
echo "${LINENO} Will work on following sites" >>${log} 

for site in $sites;
do
    echo "${LINENO} Site: ${site} " >>${log} 
done
echo "">>${log} 

#--------------------
#<Directory listing>
#--------------------
dir_check_list="Alerts AppDefaults archiving certs data eoalias icc exec formats javadriver java_uccs lock msgTracing pdls revisions scripts Tables tclprocs version views Xlate xslt"

########################################
# Site Specific Variables

#########################################
# ICC-Main Site Specific Verification #
#########################################
#-------------------------
# AutoStart FLAG to check
#-------------------------
#Dinakar -- made it generic.. It will check all SUBTYPE ws-server is set then AUTOSTART should be 0
icc_main_autostart_threads="ib_fhir_1 ib_get_cview ib_get_cdoc" 

#-------------------------
# Tables values
#-------------------------
#
#Dinakar -- see whether we can make generic
icc_main_table_check=1
icc_main_table_name="icc_settings icc_ccda_ws_settings"
icc_settings="outbound_max_read|5 log_level|3 alert_to_address|support.email@mail.com"
icc_ccda_ws_settings="hawk_key|YourHawkKey"

#-------------------------
# TCL Procs
#-------------------------
#Dinakar -- see whether it need to generic

    icc_main_tcl_check=1
    icc_main_tcl="tclprocs_lib"
    icc_main_tclprocs_lib="libtbcload1.7.so libtdom0.8.2.so pkgIndex.tcl PkgLogger.tcl tdom.tcl"

#-------------------------
#---icc_main java-----
#-------------------------
#Dinakar -- can it be generic

icc_main_java_check=1
icc_main_java="jars class"
icc_main_jars="gson-2.6.2.jar guava-14.0.jar hamcrest-core-1.1.jar hawk-core-0.13.0.jar testng-6.8.jar wealdtech-core-1.5.0.jar"

icc_main_class="CaaWsUserDataHandler.class CaaWsUserDataHandler$HttpRequestHeaderKeys.class CaaWsUserDataHandler$HttpRequestInfoKeys.class Ccda.class HawkParams.class MyTrustManager.class TpsRestResponse$1.class TpsRestResponse.class WebServiceHandler$1.class WebServiceHandler.class WebServiceParams.class AuthorizationHeaderHelper$AuthKeys.class AuthorizationHeaderHelper.class AuthorizationHeaderHelper$ExtKeys.class AuthorizationHeaderHelper$HelperData.class"


#########################
###END Variables#########
#########################
function check_alert_state ()  {
    site=$1 
    proc_prot=$2
    state=$3
    zalrt_file="/tmp/zalrtlist"
    znet_file="/tmp/zcollist"

    sitename=$(echo ${site}|awk -F/ '{print $(NF) }' ) 
    echo "============Alert state check===============">>${log} 
    echo "$site  $proc_prot $state" >>${log} 
    echo "============================================">>${log} 

    if [[ "${proc_prot}" == "process" ]]; then
        grep -Ei -A5 "process.*?${state}" ${site}/Alerts/default.alrt |grep -Ei "{ ${proc_prot} "|awk   '{print $3}'|sort -u > ${zalrt_file}
        lines=$(wc -l ${zalrt_file} |awk '{print $1}') 
        if [[ $lines == 0 ]]; then
            echo "${LINENO} ${site} ${proc_prot} ${state} is not defined " >>${log} 
            echo "<tr><td>${sitename}</td><td>${proc_prot} </td> <td><b>Fail:</b><br />Alert ${state} is not defined  </td></tr>" >>${html_file} 
            failure_count=$((failure_count+1)) 
            return 0
        fi
        grep -i "process " ${site}/NetConfig | awk '{print $2}' | sort -u > ${znet_file}

        diff ${zalrt_file} ${znet_file} > /dev/null

        if [[ $? -eq 1 ]];then
           echo "${LINENO} #### Missing ${proc_prot}  ${state}  alerts of site: ${sitename} ####" >> ${log}
           echo "${LINENO} Processes from default.alrt Processes from  NetConfig of site: ${sitename}  ">> ${log}
           diff -y --suppress-common-lines ${zalrt_file} ${znet_file} >> ${log}
           echo "<tr><td> ${sitename} </td><td>${proc_prot} </td><td><b>Fail:</b> <br/> See the differences in log file ${log}  </td> </tr>" >>${html_file} 
        else
            echo "${LINENO} No differences found between default.alrt and NetConfig for ${proc_prot} ${state} for site ${sitename} " >>${log} 

            echo "Number of lines of ${proc_prot} in default.alrt are `wc -l ${zalrt_file}` and in NetConfig are `wc -l ${znet_file}`" >>${log} 
        fi

        rm ${zalrt_file} ${znet_file}
    elif [[ ${proc_prot} == "protocol" ]]; then
#Thread check    
            grep -Ei -A5 "thread.*?${state} " ${site}/Alerts/default.alrt |awk '{if ($0 ~ "SOURCE") for(i=3;i<NF;i++) {print $i}}'|sed 's/{//;s/}//'| sort -u > ${zalrt_file}
            lines=$(wc -l ${zalrt_file} |awk '{print $1}') 
            if [[ $lines == 0 ]]; then
                echo "${LINENO} ${site} ${proc_prot} ${state} is not defined " >>${log} 
                echo "<tr><td>${sitename}</td><td>${proc_prot} </td> <td><b>Fail:</b><br />Alert ${state} is not defined  </td></tr>" >>${html_file} 
                failure_count=$((failure_count+1)) 
                return 0
            fi


            grep -E "^protocol " ${site}/NetConfig | awk '{print $2}' | sort -u > ${znet_file}

            diff ${zalrt_file} ${znet_file} > /dev/null

            if [[ $? -eq 1 ]];then
               echo "${LINENO} #### Missing ${proc_prot} ${state}  alerts in site: ${sitename} ####" >> ${log}
               echo "${LINENO} Protocols from default.alrt  from  NetConfig  of site ${sitename} ">> ${log}
               diff -y --suppress-common-lines ${zalrt_file} ${znet_file} >> ${log}

               echo "<tr><td> ${site} </td><td>${proc_prot} </td><td><b>Fail:</b> <br/> See the differences in log file ${log}  </td> </tr>" >>${html_file} 
            else
                echo "${LINENO} No differences found between default.alrt and NetConfig for ${proc_prot} ${state} for site ${sitename} " >>${log} 

                echo "Number of lines of ${proc_prot} in default.alrt are `wc -l ${zalrt_file}` and in NetConfig are `wc -l ${znet_file}`" >>${log} 
                
            fi

                rm ${zalrt_file} ${znet_file}
    fi
    return 1


} 
################################
#<NetConfig Validation>
################################
for site in $sites; 
do
        echo "%%%%%%%%%%%%%%%%%%%%%%%% working on ${site}%%%%%%%%%%%%%%%%%%" >>${log} 
        if [[ ! -d $site ]]; then
            echo "$site does not exist"
            echo "$site does not exist" >>${log}
            continue
        fi
    
        cd ${site}
        sitename=$(echo ${site}|awk -F/ '{print $(NF) }' ) 
        echo "${LINENO} sitename ${sitename}" >>${log} 
        if ! [ -d ${site} ];then
            echo "${LINENO} Invalid sitename:${sitename}" >>${log} 
            echo "<tr><td>${sitename}</td><td/><td><b>Fail:</b> <br /> Site does not exist </td></tr>" >>${html_file} 
            failure_count=$((failure_count+1)) 
        fi

        echo "${LINENO} Working on ${sitename} site" >> ${log}
        echo "${LINENO} Checking AUTOSTART FLAG : ${sitename}" >> ${log}
        echo "${LINENO} =========================">> ${log}
        echo >> ${log}

###  Check for more than one NetConfig file in the site dir
        ncfg_cnt=`ls ${site}/NetConfig* | wc -l`
        if [[ $ncfg_cnt -gt 1 ]];then
            echo "${LINENO} #### : Multiple NetConfigs found in  ${sitename} ####" >> ${log}
            ls ${site}/NetConfig* >> ${log}
            echo "<tr><td>${sitename} </td><td> NetConfig </td><td> <b>Fail:</b><br/> Multiple NetConfig files in the site directory </td></tr>">> ${html_file} 
            failure_count=$((failure_count+1))
        fi

### Check LOGCYCLESIZE exists in NetConfig 
        res=$(echo `grep LOGCYCLESIZE ${site}/NetConfig |sort -u|awk  '{print $3}' `) > /dev/null
         
        if [[ $? -eq 1 ]];then
            echo "${LINENO} #### Found different LOGCYCLESIZE settings in NetConfig to $res sizes in ${sitename}  ####" >> ${log}
            echo "<tr><td>${sitename}</td><td> NetConfig</td><td><b>Fail:</b> <br/> Multiple values for LOGCYCLESIZE ${res} </td></tr> " >>${html_file} 
            failure_count=$((failure_count)) 
        else
            echo "${LINENO} ${LINENO} All LOGCYCLESIZE has been set to $res in site ${sitename} " >>${log}
        fi

# check EODEFAULT are all empty
        res=$(grep "EODEFAULT" ${site}/NetConfig  | grep -v "EODEFAULT {}" | sort -u) > /dev/null

        if [[ $? -eq 0 ]];then
          echo "${LINENO} #### Found EODEFAULT flag enabled in NetConfig in ${sitename} ####" >> ${log}
          
          echo "<tr><td>${sitename}</td><td> NetConfig</td><td><b>Fail:</b> <br/> EODEFAULT is set in NetConfig</td></tr>" >>${html_file} 
          failure_count=$((failure_count+1)) 
        fi
# check EOCONFIG are all empty
        res=$(grep "EOCONFIG" ${site}/NetConfig  | grep -v "EOCONFIG {}" | sort -u ) > /dev/null

        if [[ $? -eq  0  ]];then
          echo "${LINENO} #### Found EOCONFIG flag enabled in NetConfig in site ${sitename}  ####" >> ${log}

          echo "<tr><td>${sitename}</td><td> NetConfig</td><td><b>Fail:</b> <br/> EOCONFIG is set in NetConfig</td></tr>" >>${html_file} 
          failure_count=$((failure_count+1)) 
        fi

# # Check DEBUG: grep NetConfig for any occurance of debug that is not debug 0, not case sensitive 
        grep -i "debug [1-9]" ${site}/NetConfig  > /dev/null
        if [[ $? -eq 0 ]];then
          echo "${LINENO} #### Found DEBUG flag enabled in NetConfig in site: ${sitename} ####" >> ${log}
          grep -i "debug [1-9]" ${site}/NetConfig >> ${log}
          echo "<tr><td>${sitename}</td><td> NetConfig</td><td><b>Fail:</b> <br/> DEBUG enabled NetConfig</td></td>" >>${html_file} 
          failure_count=$((failure_count+1)) 
        fi
################################
# Check AUTOSTART flags
###############################
        thread_names=$(awk /protocol/,/^}/ ${site}/NetConfig|awk '{if ($0 ~ "protocol") {print $2}  }') 
        for thread in $thread_names;
        do
            ws_service=$(awk /"protocol $thread"/,/^}/ ${site}/NetConfig|awk '{if ($0 ~ "ws-server") {print $3}}' )  
           autostart_status=$(grep -A1 -Ei "protocol $thread" ${site}/NetConfig|grep -i "autostart"|awk '{print $3}'  ) 
           if [[ $ws_service == 'ws-server' ]] ; then
                res=$(grep -A1 -Ei "protocol $thread" ${site}/NetConfig|grep  -B1 "AUTOSTART 1")       
                if [[ $? -eq 0 ]]; then
                    echo "${LINENO} AUTOSTART is 1 for ws-server on thread $thread site: ${sitename} " >>${log} 
                elif [[ $(autostart_status) -eq 0 ]]; then
                    echo "${LINENO} AUTOSTART is 0  for ws-server on thread $thread in site ${sitename} " >>${log}  

                    echo "<tr><td>${sitename}</td><td> ${thread} </td><td><b>Fail:</b> <br/> AUTOSTART is not set for ws-server </td></tr> " >>${html_file} 
                    failure_count=$((failure_count+1)) 
                else
                    echo "${LINENO} AUTOSTART has been set to 1 for $thread in site ${sitename} " >>${log} 
                    failure_count=$((failure_count+1)) 
                fi
           elif [[ ${autostart_status}  == 0 ]]; then
                echo "${LINENO} AUTOSTART is 0  for thread $thread in site ${sitename} " >>${log}  
           elif [[ ${autostart_status} == 1 ]]; then
                echo "${LINENO} AUTOSTART is 1  for thread $thread in site ${sitename} " >>${log}  

                echo "<tr><td>${sitename}</td><td> ${thread} </td><td><b>Fail:</b> <br/> AUTOSTART is not set to 0 </td></tr>" >>${html_file} 
                failure_count=$((failure_count+1)) 
           fi

        done
#=========================
# Check site directory 
#=========================
# Check there are now unwanted files
# list of files in site directory - grep that list for .ini .pni siteInfo NetConfig siteSecurityInfo
# This will not detect duplicate files - but the installer build process will not copy duplicates to the build site. 

        ls -l ${site}/ | grep "^-rw-" | awk '{print $9}' | grep -Ev "*.ini|*.pni|siteInfo|NetConfig|siteSecurityInfo" > /dev/null

        if [[ $? -eq 0 ]];then
           echo "${LINENO} #### Found junk files in ${sitename} directory ####" >> ${log}
           ls -l ${site}/ | grep "^-rw-" | awk '{print $9}' | grep -Ev "*.ini|*.pni|siteInfo|NetConfig|siteSecurityInfo" >> ${log}
        fi
        echo >> ${log}
        echo >> ${log}
        echo "${LINENO} Site Directory to scan : ${sitename}" >> ${log}
# Verify all required directories are present 
        echo "${LINENO} Checking directory listing in site: ${sitename} " >> ${log}
        echo "${LINENO} =========================">> ${log}
        for i in $dir_check_list;
        do
            if ! [ -d $i ];then
                echo "${LINENO} #### $i Directory is missing in site: ${sitename} ####" >> ${log}

                echo "<tr><td>${sitename}</td><td>Directory $i </td><td><b>Fail:</b> <br/> Directory does not exist</td></tr>" >>${html_file} 
                failure_count=$((failure_count+1)) 
            fi
        done
#check for unwanted directories 
       dirs=$(ls -d ${site}/*/ |awk -F/ '{print $(NF-1)}' )
       for dir in $dirs
       do
            res=$(echo $dir_check_list |grep -w $dir ) 
            if [[ $? -gt 0 ]]; then
                echo "${LINENO} $dir is unwanted directory" >>${log} 
                echo "<tr><td>${sitename}</td><td>Directory Directory Structure </td><td><b>Fail:</b> <br/><i> ${dir}</i> is not a standard directory </td></tr>" >>${html_file} 
                failure_count=$((failure_count+1)) 
            fi
       done
        ls -al|grep -E "^-rw"|awk '{print $9}'|grep -Ev "*\.ini|*\.pni|NetConfig|siteInfo|siteSecurityInfo" >/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Unsupported files in site ${sitename} directory" >>${log} 
            ls -al|grep -E "^-rw"|awk '{print $9}'|grep -Ev "*\.ini|*\.pni|NetConfig|siteInfo|siteSecurityInfo" >>${log} 
            echo "<tr><td>${sitename}</td><td>Directory Directory Structure </td><td><b>Fail:</b> <br/>${sitename} directory has unsupported files </td></tr>" >>${html_file} 
        fi

        echo >> ${log}
        echo >> ${log}
        
#=========================
# check ws-thread ini/pni 
#=========================
        echo "${LINENO} Checking thread ini files in site: ${sitename} " >> ${log}
        echo "${LINENO} =========================">> ${log}
# Verify all .ini threads are supposed to be there
# get list of ini files - grep protocol threadName NetConfig
        files=$(ls *.ini 2>/dev/null) 
        for i in $files;
        do
          thrd_to_check=`echo $i | sed -e s/.ini//`
#do exact match 
           grep -w "protocol $thrd_to_check" ${site}/NetConfig > /dev/null
           if [ $? -gt 0 ]; then
              echo "${LINENO}  #### $i file exists but no matching thread in NetConfig in site: ${sitename}    ####" >> ${log}

                echo "<tr><td>${sitename}</td><td>ini file </td><td><b>Fail:</b> <br/> ${i}  file does not have corresponding thread in NetConfig </td></tr>" >>${html_file} 
              failure_count=$((failure_count+1)) 
           fi
        done
        echo >> ${log}
        echo >> ${log}
        
        echo "${LINENO} Checking PNI files in site: ${sitename} " >> ${log}
        echo "${LINENO} =========================">> ${log}
# Verify all .pni threads are supposed to be there
# get list of pni files - grep process ProcessName NetConfig
        files=$(ls *.pni 2>/dev/null) 
        for i in $files;
        do
          prcs_to_check=`echo $i | sed -e s/.pni//`
           grep -w "process $prcs_to_check" NetConfig > /dev/null
           if [ $? -gt 0 ]; then
              echo "${LINENO}  #### $i found but no matching process in NetConfig of site: ${sitename}   ####" >> ${log}

            echo "<tr><td>${sitename}</td><td>pni file </td><td><b>Fail:</b> <br/> ${i}  file does not have corresponding process in NetConfig </td></tr>" >>${html_file} 
              failure_count=$((failure_count+1)) 
           fi
           
        done

        echo >> ${log}
        echo >> ${log}
#====================
#<Alert>
#====================
    echo "${LINENO} Checking Alerts of site: ${sitename} " >> ${log}
    echo "${LINENO} =========================">> ${log}
# grep default.alrt file for REM which indicates alerts are deactiviated. 
# 
    if [[ -d ${site}/Alerts ]] ; then 
        grep "REM 1" ${site}/Alerts/default.alrt >/dev/null
        if [ $? -eq 0 ];then
           echo "${LINENO} #### Found deactived Alerts for following threads of site: ${sitename}  ####" >> ${log}
           grep -B5 "REM" ${site}/Alerts/default.alrt | grep SOURCE |awk '{print $3}'  >> ${log}

           echo "<tr><td>${sitename}</td><td>REM 1 in default.alrt </td><td><b>Fail:</b> <br/> Found deactivated alerts </td></tr>" >>${html_file} 
        fi
#  verify there is an .alrtindex file
        if [[ ! -f ${site}/Alerts/.alrtindex ]];then
           echo "${LINENO} #### .alrtindex is missing in Alerts directory  of site: ${sitename} ####" >> ${log}
            
           echo "<tr><td>${sitename}</td><td>.alrtindex </td><td><b>Fail:</b> <br/> Missing .alrtindexfile </td></tr>" >>${html_file} 
        fi
# check for unsupported files 
        ls -a ${site}/Alerts/ | grep -Ev "^\.$|^\.\.$|default\.alrt|\.alrtindex" > /dev/null
        if [[ $? -eq 0 ]];then
           echo "${LINENO} #### Found unsupported files in Alerts directory of site: ${sitename} ####" >> ${log}
           ls -a ${site}/Alerts/ | grep -Ev "^\.$|^\.\.$|default\.alrt|\.alrtindex" >> ${log}
            
           echo "<tr><td>${sitename}</td><td>Unsupported files in Alert </td><td><b>Fail:</b> <br/> Unsupported files in Alerts directory </td></tr>" >>${html_file} 
        fi
    fi
###############################################
# check/report if thread alerts are missing. 
# made it as function so any number of states(up/dow/connection etc)
#can be checked as long as for process alerts are setup as 
#process.*state and for thread alerts are setup as thread.*state
##################################################

            check_alert_state $site "process" "up"
            check_alert_state $site "process" "down"

            check_alert_state $site "protocol" "up"
            check_alert_state $site "protocol" "down"
            check_alert_state $site "protocol" "connection"
            check_alert_state $site "protocol" "error"

        echo "=============Check for .alrtindex timestamp ===== ">>${log} 

######################################
#check to make sure .alrtindex is newer (created after )saving 
#default.alrt) 
######################################
    if [[ -f ${site}/Alerts/.alrtindex ]]; then 
        if [[ "${site}/Alerts/.alrtindex" -nt "${site}/Alerts/default.alrt"  ]]; then
            echo "${LINENO} .alrtindex file is created after default.alrt file in site ${sitename} " >>${log} 
            
        else
            echo "${LINENO} #####.alrtindex file is older than default.alrt file in site ${sitename} " >>${log} 

           echo "<tr><td>${sitename}</td><td>.alrtindex file </td><td><b>Fail:</b> <br/> .alrtindex file is older than default.alrt file </td></tr>" >>${html_file} 
            failure_count=$((failure_count+1)) 
        fi
    fi

############################
#<Check Table settings>
#Make sure there are only files with extension of .tbl and .tbl.installer
#anything else will be reported as unsupported files
############################

        echo "${LINENO} Checking Table Config of site: ${sitename} " >> ${log}
        echo "=========================">> ${log}
        if [[ -d ${site}/Tables ]]; then
            ls -a  ${site}/Tables | grep -Ev "*.tbl$|*.tbl.installer$|\.$|\.\.$" > /dev/null

                if [[ $? -eq 0 ]];then
                   echo "${LINENO} #### Found junk files in ${sitename}/Table  directory ####" >> ${log}
                   ls  -a ${site}/Tables |grep -Ev "*.tbl$|*.tbl.installer$\.$|\.\.$" >> ${log}

                   echo "<tr><td>${sitename}</td><td>Tables unwanted files </td><td><b>Fail:</b> <br/> Found unwanted files </td></tr>" >>${html_file} 
                   failure_count=$((failure_count+1)) 
                else
                    echo "${LINENO} No unwanted files in ${sitename}/Tables" >>${log} 
                fi
                echo >> ${log}
                echo >> ${log}
        else
            echo "${LINENO} ${sitename}/Tables does not exist ">>${log} 
            failure_count=$((failure_count+1)) 
        fi

#=========================================
#we need to discuss about following code to be inmplemented or not 
#
    if [[ -v ${site}_table_check ]]; then
     if [[ $((${site}_table_check)) -eq 1 ]]; then
      var=$(eval echo \$${site}_table_name)
      for i in $var;do
        var=$(eval echo \$$i)
        for j in $var;do
         ecd=$(grep -A2 `echo $j | awk -F\| '{print $1}'` ${site}/Tables/$i.tbl|tail -1|awk -F\, '{print $2}')
         if [[ $ecd -eq 1 ]];then
           ecdo=$(grep -A2 `echo $j | awk -F\| '{print $1}'` ${site}/Tables/$i.tbl|tail -2|head -1)
           outval=$(hcicrypt decrypt $ecdo | base64 -d)
          else 
           outval=$(grep -A2 `echo $j | awk -F\| '{print $1}'` ${site}/Tables/$i.tbl|tail -2|head -1)
         fi
         compval=$(echo $j | awk -F\| '{print $2}')
         if [[ $outval != $compval ]];then
           echo "#### $outval Value in $i.tbl does not match $compval ####" >> ${log}
         fi
        done
      done 
     fi
    fi

#===================================
    echo "" >> ${log}
    echo "" >> ${log}
#<>

#############################
#<Check Tclprocs settings>
#############################

        echo "${LINENO} Checking TCL libs of site: ${sitename} " >> ${log}
        echo "=========================">> ${log}
        if [[ -v ${site}_tcl_check ]];then
         if [[ $((${site}_tcl_check)) -eq 1 ]]; then
          var=$(eval echo \$${site}_tcl)
          for i in $var;do
           var2=$(eval echo \$${site}_$i)
           if [[ $i == tclprocs_lib ]];then
            ls ${site}/`echo $i | sed -e 's/_/\//'` > site_tclist
            for i in $var2;do
             grep $i site_tclist > /dev/null
             if [[ $? -eq 1 ]];then
               echo "#### $i not found ####" >> ${log}
             fi
            done
           fi
          done 
          rm site_tclist 2>/dev/null
         fi
        fi
        echo "${LINENO} Checking on ${site}/tclprocs" >>${log} 
        if [[ -d ${site}/tclprocs ]]; then 
            ls -a  ${site}/tclprocs |grep -iEv "*.tcl$|index|lib|\.$|\.\.$"  > /dev/null
            if [[ $? -eq 0 ]];then
                echo "${LINENO} found non GA tcl files in tclprocs directory of site: ${sitename} " >> ${log}
                ls -a ${site}/tclprocs/ |grep -i -Ev "\.tcl$|index|lib|\.$|\.\.$" >> ${log}

                echo "<tr><td>${sitename}</td><td>tclprocs directory unwanted files </td><td><b>Fail:</b> <br/> Found unwanted files </td></tr>" >>${html_file} 
                failure_count=$((failure_count+1)) 
            else
                echo "${LINENO} No extra files in  ${sitename}/tclprocs" >>${log} 
            fi
            grep -Ei "^ [[:blank:]]*echo*" ${site}/tclprocs/*.tcl 2>/dev/null 1>/dev/null
            if [[ $? -eq 0 ]];then
                echo "${LINENO} found echo statement/s in tclprocs of site:${sitename} " >> ${log}
                grep -Ei "^ [[:blank:]]*echo*" ${site}/tclprocs/*.tcl|sort -u >> ${log}

                echo "<tr><td>${sitename}</td><td>tclproc echo statements </td><td><b>Fail:</b> <br/> Found echo statements in tclproc </td></tr>" >>${html_file} 
              failure_count=$((failure_count+1)) 
            else
                echo "${LINENO} No echo statements found ${site}/tclprocs " >>${log} 
            fi
        else
            echo "${LINENO} ${site}/tclprocs does not exits " >>${log}  
            failure_count=$((failure_count+1)) 
        fi
        echo "" >> ${log}
        echo "" >> ${log}
#<>
######################################
#<Check java_uccs>
######################################
        echo "${LINENO} Checking java libs/class of site ${sitename} " >> ${log}
        echo "=========================">> ${log}
        if [[ -v ${site}_java_check ]];then
         if [[ $((${site}_java_check)) -eq 1 ]]; then
          var=$(eval echo \$${site}_java)
          for i in $var;do
           var2=$(eval echo \$${site}_$i)
           if [[ $i == jars ]];then
             find ${site}/java_uccs|grep jar > jar_list
             for i in $var2;do
              grep $i jar_list > /dev/null
               if [[ $? -ne 0 ]];then
                 echo "#### $i jar not found ####" >> ${log}
               fi 
              done
           fi
           if [[ $i == class ]];then
             find ${site}/java_uccs|grep class > jar_list
             for i in $var2;do
              grep $i jar_list > /dev/null
               if [[ $? -ne 0 ]];then
                 echo "#### $i class not found ####" >> ${log}
               fi 
              done
           fi
          done 
          rm jar_list
         fi
        fi
        echo "" >> ${log}
        echo "" >> ${log}
#<>

############################
#<Xlate>
# check/report for non .xlt files
# check/report for debug comments (echo *)
############################
        echo "${LINENO} Checking Xlate Directory of site: ${sitename} " >> ${log}
        echo "=========================">> ${log}
        if [[ -d ${site}/Xlate ]]; then
            ls -a ${site}/Xlate/ |grep -Evi "*.xlt$|\.$|\.\.$"  > /dev/null
            if [[ $? -eq 0 ]];then
                echo "${LINENO} found non Xlates files in Xlate directory of site: ${sitename} " >> ${log}
                ls -a ${site}/Xlate/ | grep -Ev "*.xlt$|\.$|\.\.$">> ${log}

                echo "<tr><td>${sitename}</td><td>Xlate Directory files </td><td><b>Fail:</b> <br/> Found unwanted files </td></tr>" >>${html_file} 
            else
                echo "${LINENO} No extra files in  Xlate directory of ${sitename} " >>${log} 
            fi

            grep -Ei "^ [[:blank:]]*echo*" ${site}/Xlate/*.xlt 2>&1 >/dev/null
            if [[ $? -eq 0 ]];then
                echo "${LINENO} found debug statements in Xlates files of site:${sitename} " >> ${log}
                grep -Ei "^ [[:blank:]]*echo*" ${site}/Xlate/*.xlt|awk ' !x[$0]++' >>${log} 

                echo "<tr><td>${sitename}</td><td>Xlate echo Statements </td><td><b>Fail:</b> <br/> Found echo Statements </td></tr>" >>${html_file} 
#{for(i=0;i<=NF;i++) {print $i} }' >> ${log}
            else
                echo "${LINENO} No debug statements found in ${site}/Xlate ">> ${log} 
            fi
        else
            echo "${LINENO} ${site}/Xlate directory does not exist" >>${log} 
        fi
#####################################
#check for unused xlates. Make a list of all xlates and then check in 
#NetConfig
#####################################
        echo "working on Xlate" >>${log} 
        xlt_dir="${site}/Xlate"
        xlates=""
        if [[ -d $xlt_dir ]]; then
            xlate_list=$(ls ${xlt_dir})
            for xlate in $xlate_list 
            do

                grep -c ${xlate} ${site}/NetConfig  >/dev/null
                if [[ $? -gt 0 ]]; then
                    echo "${xlate} is not used" >>${log} 
                    xlates=${xlates}${xlate} 
                fi
            done
        fi
        if [[ ${#xlates} -gt 0 ]]; then
            echo "<tr><td>${sitename}</td><td> ${xlates} </td><td> <b>Fail:</b> <br />Unused Xlates present in the directory </td></tr>" >>${html_file} 
        fi
######################################
#check for unused tcl procs present in tclprocs directory
######################################
        typeset -A used_files
        typeset -A unused_files
        index=0
        tclprocs_dir="${site}/tclprocs"
        table_dir="${site}/Tables"
        xlate_dir="${site}/Xlate"
        NetConfig="${site}/NetConfig"
        alerts_dir="${site}/Alerts"
        used=0
        if [[ -d ${tclprocs_dir}  ]] ; then 
            echo "Working on ${site}/tclprocs" >>${log} 
            tclprocs=$(cat ${tclprocs_dir}/tclIndex|awk '{ if ( $1 == "set" )printf("%s|%s\n", $2, $8 ) }'|sed 's/auto_index(//g;s/)//g;s/]]//g;s/:://' ) 

            for proc in $tclprocs
            do
                proc_name=$(echo ${proc}|awk 'BEGIN { FS = "|" }; {print $1 }' )
                tcl_file=$(echo ${proc}|awk 'BEGIN { FS = "|" }; {print $2 }' )
#check in tclprocs of site
                grep  ${proc_name} ${tclprocs_dir}/*.tcl|grep -vE "tclIndex|${tcl_file}"  >/dev/null

                if [[ $? -eq  0  ]] ; then
                    used=$((used+1)) 
                fi
#check use of proc in NetConfig
                grep ${proc_name} ${NetConfig}  >/dev/null

                if [[  $? -eq 0 ]]; then 
                    used=$((used+1)) 
                fi

#check use of tclprocs in Xlate

                grep ${proc_name} ${xlate_dir}/*.xlt  >/dev/null

                if [[ $? -eq 0 ]]; then
                    used=$((used+1)) 
                fi
#check the use of tclprocs in Alerts directory
                grep ${tcl_file} ${alerts_dir}/* >/dev/null
                
                if [[ $? -eq 0 ]] ; then
                    used=$((used+1)) 
                fi

                if [[ $used -gt 0 ]]; then
                    used_files[$tcl_file]=$tcl_file
                else
                    unused_files[$tcl_file]=$tcl_file
                fi
                used=0
            done
            for i in ${!unused_files[@]} 
            do
                if [[ "$i" == "${used_files[$i]}" ]]; then
                    unset unused_files[$i]
                fi
            done

            echo "##### Following files USED  #####">>${log} 
            for i in ${!used_files[@]} 
            do
                echo "${LINENO}---$i  used " >>${log} 
            done

            echo "##### Following files NOT USED #####" >>${log} 
            if [[ ${#unused_files[*]} -gt 0  ]] ; then 
                echo "<tr><td>${sitename} </td><td> " >>${html_file} 
                for i in ${!unused_files[@]} 
                do
                    echo "${LINENO} $i  Not used " >>${log} 
                    echo "$i <br />" >>${html_file} 
                done
                echo "</td><td> <b>Fail: </b> <br /> Extra Tcl files in the directory  </td> </tr>" >>${html_file} 
            fi
        fi
        unset used_files
        unset unused_files
############################################
#check for table usage in tclprocs, NetConfig and Xlate
###########################################

        typeset -A used_tables
        typeset -A unused_tables

        used=0
        if [[ -d ${table_dir} ]] ; then 
            echo "Started working with ${site}/Tables" >>${log} 
            for table_name in `ls ${table_dir}|grep -vE "installer"`
            do
                table=$(echo $table_name |sed 's/.tbl//') 
                grep ${table} ${tclprocs_dir}/*.tcl >/dev/null
                if [[ $? -eq 0  ]]; then
                    used=$((used+1)) 
                fi

                grep $table ${xlate_dir}/*.xlt >/dev/null
                if [[ $? -eq 0 ]]; then
                    used=$((used+1)) 
                fi

                grep $table ${NetConfig} >/dev/null 
                if [[ $? -eq 0 ]]; then
                    used=$((used+1)) 
                fi

                if [[ $used -gt 0 ]]; then
                    used_tables[$table]=$table
                else
                    unused_tables[$table]=$table
                fi
                used=0

            done
            echo "########## Following tables Used ##########" >>${log} 
            for i in ${!used_tables[@]} 
            do
                echo "$i ===  used  " >>${log} 

            done
            if [[ ${#unused_tables[*]} -gt 0 ]] ; then
                echo "########## Following Not tables Used ##########" >>${log} 
                echo "<tr><td>${sitename} </td><td>" >>${html_file} 
                for i in ${!unused_tables[@]} 
                do
                    echo "$i -------- Not used" >>${log} 
                    echo "$i <br />" >>${html_file} 
                    html=1

                done
                echo "</td><td> <b> Fail: </b> <br /> Unused table/s present </td></tr> ">>${html_file} 
            fi
        fi
        unset unused_tables
        unset used_tables
##############################
##End Verficiation ###########
##############################

#<display verification status>#
done #end of sites loop

if [[ $failure_count -gt 0 ]]; then
    echo "${LINENO} Build validation for all sites ${sites} with failure_count of $failure_count" >>${log} 
fi
grep "#####" ${log}  > /dev/null
if [ $? -eq 0 ]; then
  echo "######### Build Verification Failed #########" >>${log} 
  echo "######### check report for error details ${log} #########"
else
  echo "Build Verification complete!" >>${log} 
fi
echo "</table></body></html> " >>${html_file}  
echo "Build Verification complete!"
echo "Process ended at `date` and detailed output file is found at: ${log} "
echo "Process ended at `date` and please check report file: ${html_file} "

