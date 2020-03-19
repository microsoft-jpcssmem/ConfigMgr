#################################################
## 基本設定
#################################################

# サイト構成
$SiteCode = "P01" # サイト コード 
$ProviderMachineName = "sccm01.tkaji.local" # SMS プロバイダーのマシン名

# ファイル出力先
$work_dir =    "C:\temp"            # 作業フォルダ
$output_file = "export_sw_grps.csv" # 出力先CSVファイル名

#################################################
## 準備
#################################################

$initParams = @{}

# ConfigurationManager.psd1 モジュールをインポートします 
if( $null -eq (Get-Module ConfigurationManager)){
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# サイトのドライブに接続します (まだ存在しない場合)
if( $null -eq  (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# 現在の場所をサイト コードに設定します。
Set-Location "$($SiteCode):\" @initParams

#################################################
## 処理
#################################################

$sw_update_grps = @()

# SoftwareUpdateGroupの一覧を取得する。
Write-Host "ソフトウェア更新グループ一覧を取得します。"
$get_duration = Measure-Command{
    $sw_update_grps = Get-CMSoftwareUpdateGroup | Select-Object CI_ID, LocalizedDisplayName, LocalizedDescription, DateCreated, DateLastModified
}
$get_duration_msec = $get_duration.TotalMilliseconds
$sw_update_grps_ct = $sw_update_grps.Length

Write-Host "ソフトウェア更新グループ一覧を取得しました。"
Write-Host "取得件数:${sw_update_grps_ct}件, 取得時間:${get_duration_msec}ミリ秒。"

# ファイルを扱うため、現在の場所をFileSystemへ戻す
Set-Location $work_dir

# 取得した一覧に残存チェックの項目をつける
foreach ($sw_update_grp in $sw_update_grps){
    $sw_update_grp | Add-Member RemainCheck "" 
}

# 作成した一覧をCSVに出力する。
$sw_update_grps | Export-Csv -Delimiter ',' -LiteralPath $output_file -Encoding Default

Write-Host "ソフトウェア更新グループ一覧をCSVファイルに出力しました。"
Write-Host "出力先: ${work_dir}\${output_file}"

#################################################
## 後処理
#################################################

# サイトドライブの接続を切る。
if($null -ne (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    Remove-PSDrive -Name $SiteCode -PSProvider CMSite -Force
}
