#################################################
## 基本設定
#################################################

$work_dir =    "C:\temp"            # 作業フォルダ
$input_file = "export_sw_grps.csv"  # 入力ファイル名

$output_file_name = "remove_canditate_sw_grps" # 出力先ファイル名

$split_number = 100  #ファイル分割時の行数

#################################################
## 処理
#################################################

Write-Host "${work_dir}\${input_file}を読み込み、RemainCheckが1以外のアイテムを削除対象としてリスト化します。"
Write-Host "リストは${split_number}個ずつのCSVファイルに分割されます。分割前の削除対象もCSVファイルとして出力されます。"

Set-Location $work_dir
$sw_updt_grps = Import-CSV -Path $input_file | Where-Object RemainCheck -ne "1"

$mod = $sw_updt_grps.Count % $split_number

if($mod -eq 0){
    $file_number = $sw_updt_grps.Count / $split_number
}else{
    $file_number = [Math]::Floor($sw_updt_grps.Count / $split_number) + 1
}

for($i = 0; $i -lt $file_number; $i++){
    $begin = $i * $split_number

    if($i -eq ($file_number - 1) -and ($mod -gt 0)){
        $end_range = $mod
    }else{
        $end_range = $split_number
    }
    $end = ($begin + $end_range) - 1

    $output_file_path = "${work_dir}\${output_file_name}_${i}.csv"    
    $sw_updt_grps[$begin..$end] | Export-CSV -Path $output_file_path -Encoding Default    
    Write-Host "${i}番目のファイル ${output_file_path}を生成しました。"
}
$output_all_data_file_path = "${work_dir}\${output_file_name}_all.csv"    
$sw_updt_grps | Export-CSV -Path $output_all_data_file_path -Encoding Default    

