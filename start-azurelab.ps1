$modules = get-module AZ.*
if ($modules.name -notcontains 'Az.Compute') {
    if ((get-module -ListAvailable).name -contains 'AZ' ) {
        import-module az -force
    }
    else {
        install-module az -Force -AllowClobber
    }
    
}
$jsoncontent = (get-content $PSScriptRoot\config.json) | convertfrom-json
$tenantid = $jsoncontent.TenantId
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) { Login-AzAccount }

foreach ($sub in $jsoncontent.subscriptions) {
    $subscription = $null
    write-host "Started processing on subscription" $sub.subscription_name -ForegroundColor Green
    try {
        $subscription = Select-AzSubscription -Subscription $sub.subscription_name -ErrorAction stop
    }
    catch {
        write-host " - Failed to select subscription." $_ -ForegroundColor Red
    }
    if ($subscription) {
        foreach ($group in $sub.resource_groups) {
            write-host "Started processing on group" $group.resource_group_name -ForegroundColor Green
            foreach ($vm in $group.data.virtual_machines) {
                write-host "Started processing on VM" $vm.vm_name -ForegroundColor Green
                try {
                    if ($vm.wait){
                        Start-AzVM -Name $vm.vm_name -ResourceGroupName $group.resource_group_name -ErrorAction Stop | out-null
                    }
                    else{
                        Start-AzVM -Name $vm.vm_name -ResourceGroupName $group.resource_group_name -ErrorAction Stop -NoWait | out-null
                    }
                    write-host "VM" $vm.vm_name "started.  Waiting" $vm.delay_after_start "seconds" -ForegroundColor Green
                    start-sleep $vm.delay_after_start
                }
                catch {
                    write-host " - Failed to start VM" $vm.vm_name  $_ -ForegroundColor Red
                }
            }
        }
    }
}