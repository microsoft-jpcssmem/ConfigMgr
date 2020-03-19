#################################################
## 基本設定
#################################################

#引数指定
Param($input_file_path)

# サイト構成
$SiteCode = "P01" # サイト コード 
$ProviderMachineName = "sccm01.tkaji.local" # SMS プロバイダーのマシン名

$work_dir =    "C:\temp" # 作業フォルダ
$script_log_path  = "${work_dir}\remove_sw_grps.log"

# FileCheck
if ($input_file_path -eq $null){
    Write-Host "削除対象のソフトウェア更新グループ一覧を指定してください。"
    exit
}

if ((Test-Path -Path $input_file_path) -eq $false){
    Write-Host "ファイル${input_file_path}が存在しません。"
    exit
}

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
# コンソールとログにメッセージを出力する関数
function SimpleOutputAndLogger(){
    Param(
        [string] $Level,
        [string] $Message
    )
    $time = Get-Date -Format "yyyy-mm-dd-hh:mm:ss"
    $log_line = "${time},${level},${message}"
    Write-Host $message
    $log_line|Out-File -FilePath $script_log_path -Append -Encoding Default 
}


#################################################
## 処理
#################################################

Write-Host "${input_file_path}から削除するソフトウェア更新グループを読み込みます。"
$remove_target_sw_grps = Import-CSV -Path $input_file_path -Encoding Default
$remove_count = $remove_target_sw_grps.Count
Write-Host "${remove_count}個の削除候補を読み込みました。"

$remove_option = Read-Host "削除しますか? [y/削除開始 other/終了]:"
if($remove_option -ne "y"){ 
    Write-Host "削除せずに終了します。"
    exit
 }

$msg = "ソフトウェア更新グループの削除を開始します。読み込み元は${input_file_path}です。"
SimpleOutputAndLogger -Level "info" -Message $msg

$index = 0
$remove_duration = Measure-Command{
    foreach($remove_target_sw_grp in $remove_target_sw_grps){
        if($remove_target_sw_grp.CI_ID -eq $null){ break }
        else{
            # 現在の場所をサイト コードに設定します。
            Set-Location "$($SiteCode):\" @initParams
            Remove-CMSoftwareUpdateGroup -Id $remove_target_sw_grp.CI_ID -Confirm:$false -Force
            # ファイルを扱うためロケーションを戻します。
            Set-Location $work_dir
            $sw_grp_name = $remove_target_sw_grp.LocalizedDisplayName
            $remove_msg = "${index}番目のソフトウェア更新グループ「${sw_grp_name}」を削除しました."
            SimpleOutputAndLogger -Level "info" -Message $remove_msg
            $index++
        }        
    }
}
$duration_minutes = $remove_duration.TotalMinutes
$result_msg = "${input_file_path}に記載のソフトウェア更新グループを削除しました。経過時間: ${duration_minutes}分。"
SimpleOutputAndLogger -Level "info" -Message $result_msg


#################################################
## 後処理
#################################################

# サイトドライブの接続を切る。
if($null -ne (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    Remove-PSDrive -Name $SiteCode -PSProvider CMSite -Force
}



