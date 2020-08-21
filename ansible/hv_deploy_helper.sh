su -l admin
export HV_ROOTPASS=hedvig
export HV_MEM_PROFILE=small_demo
/opt/hedvig/bin/hv_deploy --destroy_cluster hotelvictor
/opt/hedvig/bin/hv_deploy --deploy_new_cluster /tmp/hv_deploy.cfg