$Root = (Get-Location).Path

Write-Host "================ KAO ID FILE INVENTORY ================"

Get-ChildItem "$Root\lib\features\kao_id" -Recurse -File -Filter "*.dart" |
    Sort-Object FullName |
    ForEach-Object {
        $_.FullName.Substring($Root.Length + 1)
    }

Write-Host ""
Write-Host "================ KAO ID DATABASE MIGRATIONS ================"

Get-ChildItem "$Root\supabase\migrations" -File -Filter "*.sql" |
    Sort-Object Name |
    ForEach-Object {
        $_.FullName.Substring($Root.Length + 1)
    }

Write-Host ""
Write-Host "================ KAO ID KEYWORDS ================"

Get-ChildItem "$Root\lib\features\kao_id" -Recurse -File -Filter "*.dart" |
    Select-String -Pattern "register|login|logout|profile|identity|kyc|device|session|organization|company|business|legal|oauth|permission|role|security" -CaseSensitive:$false |
    ForEach-Object {
        $file = $_.Path.Substring($Root.Length + 1)
        "$file : $($_.LineNumber) : $($_.Line.Trim())"
    }

Write-Host ""
Write-Host "================ KAO ID SQL KEYWORDS ================"

Get-ChildItem "$Root\supabase\migrations" -File -Filter "*.sql" |
    Select-String -Pattern "profiles|identity|kyc|devices|sessions|organization|organizations|company|companies|business|legal|oauth|permission|role|security" -CaseSensitive:$false |
    ForEach-Object {
        $file = $_.Path.Substring($Root.Length + 1)
        "$file : $($_.LineNumber) : $($_.Line.Trim())"
    }
