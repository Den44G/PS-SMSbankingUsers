Get-SqlData "srv-db" ibank2ua "select distinct a.client_id
from ibank2ua.clients a, ibank2ua.employees b ,ibank2ua.channels_settings c
where convert(int,channel_perms)&4096 != 0
and a.client_id=b.client_id
and b.status = 2
and b.client_id=c.client_id
and c.type='sms'
and c.act_time >'20121106'" |Select @{Name="Название";Expression={$_."client_id"}}|add-Content C:\MsSQL\SmsCh1.txt
Get-Content C:\MsSQL\SmsCh1.txt| %{$_.substring(11)}|%{$_.trimend('}')}|sort-object| Set-Content C:\MsSQL\SmsChR.txt
$dif = Compare-Object -ReferenceObject $(Get-Content C:\MsSQL\smsoff.txt) -DifferenceObject $(Get-Content C:\MsSQL\SmsChR.txt) -IncludeEqual
$excel = new-object -comobject excel.application
$excel.visible = $true
$workbook = $excel.workbooks.add()
$workbook.workSheets.item(3).delete()
$workbook.WorkSheets.item(2).delete()
$workbook.WorkSheets.item(1).Name = "Користувачі СМС-банкінгу"
$sheet = $workbook.WorkSheets.Item("Користувачі СМС-банкінгу")
$x=2
$lineStyle = "microsoft.office.interop.excel.xlLineStyle" -as [type]
$colorIndex = "microsoft.office.interop.excel.xlColorIndex" -as [type]
$borderWeight = "microsoft.office.interop.excel.xlBorderWeight" -as [type]
$chartType = "microsoft.office.interop.excel.xlChartType" -as [type]
For($b = 1 ; $b -le 4 ; $b++)
{
 $sheet.cells.item(1,$b).font.bold = $true
 $sheet.cells.item(1,$b).font.size = 14
 $sheet.cells.item(1,$b).borders.LineStyle = $lineStyle::xlDashDot
 $sheet.cells.item(1,$b).borders.ColorIndex = $colorIndex::xlColorIndexAutomatic
}
$sheet.cells.item(1,1) = "Ід клієнта"
$sheet.cells.item(1,2) = "Назва"
$sheet.cells.item(1,3) = "ЕДРПОУ"
$sheet.cells.item(1,4) = "Статус"
foreach ($difference in $dif)
{
if($difference.SideIndicator -eq "==" )
{
get-sqldata "srv-db" ibank2ua "select distinct a.name_cln,a.client_id,a.okpo
from ibank2ua.clients a, ibank2ua.employees b ,ibank2ua.channels_settings c
where convert(int,channel_perms)&4096 != 0
and a.client_id=b.client_id
and b.status = 2
and b.client_id=c.client_id
and c.type='sms'
and c.act_time >'20121106'" | where {$_.client_id -eq $difference.InputObject}|
ForEach-Object {
$sheet.cells.item($x,1) = $_.client_id
$sheet.cells.item($x,2) = $_.name_cln
$sheet.cells.item($x,2).font.bold =$true
$sheet.cells.item($x,3) = $_.okpo
$sheet.cells.item($x,4) = "Без изменений"
$x++
}}
elseif ($difference.SideIndicator -eq "=>" ){
get-sqldata "srv-db" ibank2ua "select distinct a.name_cln,a.okpo,a.client_id
from ibank2ua.clients a,ibank2ua.channels_settings b
where a.client_id = b.client_id
and b.type = 'sms'
and b.act_time >'20121106'" | where {$_.client_id -eq $difference.InputObject}|
ForEach-Object {
$sheet.cells.item($x,1) = $_.client_id
$sheet.cells.item($x,2) = $_.name_cln
$sheet.cells.item($x,2).font.bold =$true
$sheet.cells.item($x,3) = $_.okpo
$sheet.cells.item($x,4) = "Подключился"
$x++
}}
elseif ($difference.SideIndicator -eq "<=" ){
get-sqldata "srv-db" ibank2ua "select distinct a.name_cln,a.okpo,a.client_id
from ibank2ua.clients a,ibank2ua.channels_settings b
where a.client_id = b.client_id
and b.type = 'sms'
and b.act_time >'20121106'" | where {$_.client_id -eq $difference.InputObject}|
ForEach-Object {
$sheet.cells.item($x,1) = $_.client_id
$sheet.cells.item($x,2) = $_.name_cln
$sheet.cells.item($x,2).font.bold =$true
$sheet.cells.item($x,3) = $_.okpo
$sheet.cells.item($x,4) = "Отключился"
$x++
}}
}
$usedRange=$sheet.UsedRange
$usedRange.EntireColumn.Autofit() |Out-Null #Форматируется весь диапазон данных по значению.
$excel.DisplayAlerts = $false
$excel.AlertBeforeOverwriting = $false
$WorkBook.SaveAs('C:\MsSQL\SmsCln.xls')
$Excel.Quit()
