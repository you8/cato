#!/usr/bin/env tclsh

#########################################################################
# Copyright 2011 Cloud Sidekick
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#########################################################################

set PROCESS_NAME cato_ecosync
set ::CATO_HOME [file dirname [file dirname [file dirname [file normalize $argv0]]]]
source $::CATO_HOME/services/bin/common.tcl
read_config

### the following code is depricated. Need to change to read from the cloud_providers.xml file. Workaround below
#proc get_object_types {} {

#	set sql "select cloud_object_type, api, api_call, describe_parameter, result_xpath from cloud_object_type"
#	set object_types [::mysql::sel $::CONN $sql -list]
#	foreach object_type $object_types {
#		set ::OBJECT_TYPES([lindex $object_type 0]) [lrange $object_type 1 end]
#	}
#}
proc get_object_types {} {

	lappend ::OBJECT_TYPES(aws_as_group) as DescribeAutoScalingGroups AutoScalingGroupNames.member.N //AutoScalingGroupName 
	lappend ::OBJECT_TYPES(aws_ec2_address) ec2 DescribeAddresses PublicIp.n //publicIp 
	lappend ::OBJECT_TYPES(aws_ec2_image) ec2 DescribeImages ImageId.n //imageId 
	lappend ::OBJECT_TYPES(aws_ec2_instance) ec2 DescribeInstances InstanceId.n //instancesSet/item/instanceId 
	lappend ::OBJECT_TYPES(aws_ec2_keypair) ec2 DescribeKeyPairs KeyName.n //keyName 
	lappend ::OBJECT_TYPES(aws_ec2_security_group) ec2 DescribeSecurityGroups GroupName.n //groupName 
	lappend ::OBJECT_TYPES(aws_ec2_snapshot) ec2 DescribeSnapshots SnapshotId.n //snapshotId 
	lappend ::OBJECT_TYPES(aws_ec2_spotinstance) ec2 DescribeSpotInstanceRequests {} {} 
	lappend ::OBJECT_TYPES(aws_ec2_volume) ec2 DescribeVolumes {} //Volume 
	lappend ::OBJECT_TYPES(aws_elb_balancer) elb DescribeLoadBalancers LoadBalancerNames.member.N //LoadBalancerName 
	lappend ::OBJECT_TYPES(aws_emr_jobflow) emr DescribeJobFlows JobFlowIds.member.N //JobFlowId 
	lappend ::OBJECT_TYPES(aws_rds_instance) rds DescribeDBInstances DBInstanceIdentifier //DBInstance/DBInstanceIdentifier 
	lappend ::OBJECT_TYPES(aws_rds_snapshot) rds DescribeDBSnapshots DBInstanceIdentifier //DBName 
	lappend ::OBJECT_TYPES(aws_sdb_domain) sdb ListDomains {} //DomainName 


}
proc add_new_objects {objects cloud_id object_type ecosystem_id} {
	
	foreach object_id $objects {
		set sql "insert into ecosystem_object (ecosystem_id, cloud_id, ecosystem_object_id, ecosystem_object_type, added_dt) values ('$ecosystem_id', '$cloud_id', '$object_id','$object_type',now())"
		::mysql::exec $::CONN $sql
		output "Adding $object_id of type $object_type to $ecosystem_id" 
	}
}
proc remove_old_objects {objects object_type account_id cloud_id} {
	
	foreach object_id $objects {
		set sql "delete ecosystem_object from ecosystem_object eo join ecosystem e where e.account_id = '$account_id' and eo.ecosystem_object_type = '$object_type' and eo.ecosystem_object_id = '$object_id' and eo.cloud_id = '$cloud_id'" 
		::mysql::exec $::CONN $sql
		output "Deleting $object_id of type $object_type from account id $account_id and cloud id $cloud_id" 
	}
}
proc get_clouds {} {

	unset -nocomplain ::cloud_arr

        set clouds [get_clouds_provider {Amazon AWS}]
        foreach cloud $clouds {
		lappend ::cloud_arr([lindex $cloud 0]) {Amazon AWS} [lindex $cloud 1] [lindex $cloud 2]
        }

	set sql "select cloud_id, provider, cloud_name, api_url from clouds"
	set  clouds [::mysql::sel $::CONN $sql -list]
	foreach cloud $clouds {
		lappend ::cloud_arr([lindex $cloud 0]) [lindex $cloud 1] [lindex $cloud 2] [lindex $cloud 3]
	}
	#output "[parray ::cloud_arr]"
}
proc get_cloud_objects {cloud_id account_id} {

	set sql "select distinct do.ecosystem_object_id, do.ecosystem_object_type from ecosystem_object do join ecosystem e where do.cloud_id = '$cloud_id'  and e.account_id = '$account_id' order by do.ecosystem_object_type"
	set  objects [::mysql::sel $::CONN $sql -list]
	foreach object $objects {
		lappend obj_arr([lindex $object 1]) [lindex $object 0]
	}	
	foreach object_type [array names obj_arr] {
		#output "checking $object_type"
		set old_objects [get_object_status $object_type $cloud_id $account_id $obj_arr($object_type)]
		#output "old objects are $old_objects"
		if {"$old_objects" > ""} {
			remove_old_objects $old_objects $object_type $account_id $cloud_id
		}
	}
}
proc parse_results {path result} {
	set xmldoc [dom parse -simple $result]
        set root [$xmldoc documentElement]
        set xml_no_ns [[$root removeAttribute xmlns] asXML]
        $root delete
        $xmldoc delete
        set xmldoc [dom parse -simple $xml_no_ns]
        unset xml_no_ns
        set root [$xmldoc documentElement]
        set items [$root selectNodes $path]
	set results ""
        foreach item $items {
                ##output "its [$item selectNodes string(.)]" 
		lappend results [$item selectNodes string(.)]
        }
        $root delete
        $xmldoc delete
	return $results
}
proc check_cloud_objects {} {
	set sql "select distinct eo.cloud_id, e.account_id from ecosystem_object eo join ecosystem e on eo.ecosystem_id = e.ecosystem_id"
	set  cloud_accounts [::mysql::sel $::CONN $sql -list]
	foreach {cloud_account} $cloud_accounts {
		#set ::AS_XML ""
		#set ::EC2_INSTANCES ""
		get_cloud_objects [lindex $cloud_account 0] [lindex $cloud_account 1]
		#check_as_instances [lindex $ecosystem 1]
		#unset ::AS_XML ::EC2_INSTANCES
	}
}
proc get_object_status {object_type cloud_id account_id objects} {

	get_account_creds $account_id	
	set counter 0
	set one_at_atime 0
	set old_objects ""
	set params {}
	#output "$object_type $cloud_id $account_id $objects"
	#foreach object $objects {
	#	set param_name [lindex $::OBJECT_TYPES($object_type) 2]
	#	##output "$object, $object_type [lindex $::OBJECT_TYPES($object_type) 0], param name is $param_name"
	#	if {"[string tolower [string range $param_name end-1 end]]" == ".n"} {
	#		incr counter
	#		set param_name "[string range $param_name 0 end-1]$counter"
	#		lappend params $param_name
	#		lappend params $object
	#	} else {
	#		lappend params $param_name
	#		lappend params $object
	#		set cmd "$::ACCOUNT_HANDLE call_aws [lindex $::OBJECT_TYPES($object_type) 0] {} [lindex $::OBJECT_TYPES($object_type) 1]"
	#		lappend cmd $params
	#		set one_at_atime 1
	#		if {[catch {set return_val [eval $cmd]} errMsg]} {
	#			set return_val $errMsg
	#		}
	#		##output ">>>>>>$return_val<<<<<<"
	#		lappend results [parse_results [lindex $::OBJECT_TYPES($object_type) 3] $return_val]
	#	}
	#	
	#}
	#if {"$object_type" == "aws_ec2_instance"} {
	#	lappend params Filter.1.Name instance-state-name Filter.1.Value.1 pending Filter.1.Value.2 running Filter.1.Value.3 shutting-down Filter.1.Value.4 stopping Filter.1.Value.5 stopped
	#}
	#output "$account_id = $::OBJECT_TYPES($object_type)"
	if {$one_at_atime == 0} {
		if {"[lindex $::cloud_arr($cloud_id) 0]" == "Eucalyptus"} {
			lappend region_endpoint [lindex $::cloud_arr($cloud_id) 1] "[lindex $::cloud_arr($cloud_id) 2]/services/Eucalyptus" http
		} else {
			set region_endpoint ""
		}
		tclcloud::configure aws $::CLOUD_LOGIN_ID $::CLOUD_LOGIN_PASS $region_endpoint
		set cmd "tclcloud::call [lindex $::OBJECT_TYPES($object_type) 0] [lindex $::cloud_arr($cloud_id) 1] [lindex $::OBJECT_TYPES($object_type) 1]"
		lappend cmd $params
		#output $cmd
		set return_val [eval $cmd]
	}
	foreach object $objects {
		set results [parse_results [lindex $::OBJECT_TYPES($object_type) 3] $return_val]
	}
	##output ">>>> Objects are $objects, results are $results"
	package require struct::set
	set old_objects [::struct::set difference $objects $results]
	#if {"$object_type" == "aws_ec2_instance"} {
		##output "return_val is $return_val"
		##output "objects is $objects"
		##output "results is $results"
		
	#	set ::EC2_INSTANCES [::struct::set difference $results $objects]
	#}
	#if {"$object_type" == "aws_as_group"} {
	#	set ::AS_XML $return_val
	#}
	set old_objects [::struct::set difference $objects $results]
	return $old_objects
}
proc check_as_instances {ecosystem_id} {
	# extract ec2 instances from AS xml and cross reference from the instances not in the ecosystem
	# if they already are not in the ecosystem, add them to the ecosystem
	##output "as xml = $::AS_XML"
	##output "ec2 instance = $::EC2_INSTANCES"
	if {"$::EC2_INSTANCES" == ""} {
		lappend params Filter.1.Name instance-state-name Filter.1.Value.1 pending Filter.1.Value.2 running Filter.1.Value.3 shutting-down Filter.1.Value.4 stopping Filter.1.Value.5 stopped
                tclcloud::configure aws $::CLOUD_LOGIN_ID $::CLOUD_LOGIN_PASS
		set cmd "tclcloud::call ec2 {} DescribeInstances"
		lappend cmd $params
		set return_val [eval $cmd]
		set ::EC2_INSTANCES [parse_results //instancesSet/item/instanceId $return_val]
		#output "ec2 instance = $::EC2_INSTANCES"
	}
	if {"$::AS_XML" > "" && "$::EC2_INSTANCES" > ""} {
		set as_instances [parse_results //InstanceId $::AS_XML]
		set new_instances [::struct::set intersect $::EC2_INSTANCES $as_instances]
		##output "new instances = $new_instances"
		if {"$new_instances" > ""} {
			add_new_objects $new_instances $cloud_id aws_ec2_instance $ecosystem_id
		}
	}
	
}
proc get_account_creds {account_id} {
	if {"$::ACCOUNT_ID" != "$account_id"} {	
		set sql "select login_id, login_password, provider from cloud_account where account_id = '$account_id'"
		set creds [::mysql::sel $::CONN $sql -list]
		set ::ACCOUNT_ID $account_id
		set ::CLOUD_LOGIN_ID [lindex [lindex $creds 0] 0]
		set ::CLOUD_LOGIN_PASS [decrypt_string [lindex [lindex $creds 0] 1] $::SITE_KEY]
		#set ::ACCOUNT_HANDLE [::tclcloud::connection new $::CLOUD_LOGIN_ID $::CLOUD_LOGIN_PASS]

	}

}
proc get_settings {} {
}
proc initialize_process {} {
	package require tclcloud
	package require tdom
	get_object_types
}

proc main_process {} {

	set ::ACCOUNT_ID ""
	#get_ecosystems
	get_clouds
	check_cloud_objects
}	
main 
#if {[catch {main [lindex $argv 1]} errMsg]} {
#	output "Poller Error -> $errMsg"
#}
