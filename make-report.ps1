param([string]$study)

if(!$study) {
	write-host "You must indicate which study you want to report on.";
	return;
}

if(! (test-path ".\data\studies\$study\") ) {
	write-host "Sorry. We were unable to find the data for study '$study'";
	return;
}

$participants = Get-ChildItem ".\data\studies\$study\participants\*.json" -recurse | get-content| convertfrom-json
$experiments  = Get-ChildItem ".\data\studies\$study\experiments\*.json"  -recurse | get-content| convertfrom-json

$participant_hash = $participants | % { @{"$($_.id)" = $_ } }

#touch statistics between all experiments for a participant
$participant_experiment_stats = $experiments | Sort InsertTimeStamp | Group 'ParticipantId' | Select `
	 @{Name="E_CNT"      ;Expression={ $_.Count } } `
	,@{Name="P_ID"       ;Expression={ $_.Name  } } `
	,@{Name="ONE_T"      ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'T_N' }} `
	,@{Name="TWO_T"      ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'T_N' }} `
	,@{Name="ONE_O"      ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'O_N' }} `
	,@{Name="TWO_O"      ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'O_N' }} `
	,@{Name="ONE_E"      ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'Id' }} `
	,@{Name="TWO_E"      ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'Id' }} `
	,@{Name="ONE_R"      ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'RewardId' }} `
	,@{Name="TWO_R"      ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'RewardId' }} `
	,@{Name="ONE_F"      ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'FPS' }} `
	,@{Name="TWO_F"      ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'FPS' }} `
	,@{Name="ONE_TS"     ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'InsertTimeStamp' }} `
	,@{Name="TWO_TS"     ;Expression={ $_.Group | Select -Skip 1 -First 1 -ExpandProperty 'InsertTimeStamp' }} `
	,@{Name="Resolution" ;Expression={ $_.Group | Select -Skip 0 -First 1 -ExpandProperty 'Resolution' }} `

$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Machine"=($participant_hash.$($_.P_ID)).Machine} -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Age"    =($participant_hash.$($_.P_ID)).Age    } -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Gender" =($participant_hash.$($_.P_ID)).Gender } -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"First"  =($participant_hash.$($_.P_ID)).First  } -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Input"  =($participant_hash.$($_.P_ID)).Device } -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Browser"=($participant_hash.$($_.P_ID)).Browser} -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"System" =($participant_hash.$($_.P_ID)).System } -PassThru }
$participant_experiment_stats = $participant_experiment_stats | % { $_ | Add-Member @{"Study"  =($participant_hash.$($_.P_ID)).StudyId} -PassThru }

Write-Host $participant_experiment_stats.Count

$participant_experiment_stats