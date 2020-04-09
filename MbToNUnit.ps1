#MbToNunit
param([string]$folderPath="")

#Global var, used in functions also main scripts
$timeTag = Get-Date -Format "yyyy-MM-dd_HHmmss"
$m_logFile = Join-Path $folderPath "MbToNUnit_$timeTag.log"

$searchReplaceTag = @(
@("MbUnit\.", "NUnit."),
@("Gallio\.", "NUnit."),
@("\[FixtureSetUp\]", "[OneTimeSetUp]"),
@("Importance\(.+?\)", " "),
@("Assert.AreEqual\<.+?\>\(", "Assert.AreEqual("),
@("Assert.AreEqual\(Of.+?\)(\(|\))*\(", "Assert.AreEqual("),
@("Assert.AreApproximatelyEqual\(Of.+?\)(\(|\))*\(", "Assert.AreEqual("),
@("Assert.AreApproximatelyEqual\<.+?\>\(", "Assert.AreEqual("),
@("Assert.AreApproximatelyEqual\(", "Assert.AreEqual("),
@("Assert.AreNotEqual\<.+?\>\(", "Assert.AreNotEqual("),
@("Assert.AreSame\<.+?\>\(", "Assert.AreSame("),
@("Assert.AreNotSame\<.+?\>\(", "Assert.AreNotSame("),
@("Assert.AreNotEqual\(Of.+?\)\(", "Assert.AreNotEqual("),
@("Assert.IsInstanceOfType", "Assert.IsInstanceOf"),
@("\<Column\(", "<Values("),
@("\[Column\(", "[Values("),
@("^Column\(", "Values("),
@("\[EnumData\(.+?\)\)", "[Values"),
@("\<EnumData\(.+?\)\)", "<Values"),
@("(,|\s)*AccurevIssue\(.+?\)", " "),
@("(,|\s)*JiraTicket\(.+?\)", " "),
@("\<CTest", "<Test"),
@("\[CTest", "[Test"),
@("\sRow\(", " TestCase("),
@("^Row\(", "TestCase("),
@("\<Row\(", "<TestCase("),
@("\[Row\(", "[TestCase("),
@("(,|\s)*MultipleAsserts\(\),*", ", "),
@("(,|\s)*MultipleAsserts,*", ", "),
@("Assert.StartsWith", "StringAssert.StartsWith"),
@("Assert.Contains", "StringAssert.Contains"),
@("Assert.DoesNotContain", "StringAssert.DoesNotContain"),
@("Assert.AreElementsEqual\(", "CollectionAssert.AreEqual("),
@("Assert.AreElementsEqualIgnoringOrder\(", "CollectionAssert.AreEquivalent("),
@("Assert.LessThan", "Assert.Less"),
@("Assert.GreaterThan", "Assert.Greater"),
@("CombinatorialJoin", "Combinatorial"),
@("Assert.AreSame\(Of.+?\)\(", "Assert.AreSame("),
@("Assert.LessOrEqualTo", "Assert.LessOrEqual")
)

$searchCleanTag = @(
@("\,\s(\s|_|\n|,)*\>", ">"),
@("^\s*\<(,|\s)*?\>\s*_*", " "),
@("^\s*\[(,|\s)*?\]\s*_*", " ")
)
    
function Log_To_File($log_msg, $log_file_path)
{
    if (Test-Path -Path $log_file_path)
    {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $message = "[$time] $log_msg"
        Add-Content $log_file_path $message
        Write-Host $log_msg
    }
}

class SearchReplaceParser
{
    [string]$logFile
    [string]$originContent
    [string]$modifiedContent
    $searchReplaceTag

    SearchReplace()
    {
        $content = $this.originContent    
        foreach($tag in $this.searchReplaceTag)
        {
            $pattern = $tag[0]
            $replace = $tag[1]           
            $matchcount = [regex]::matches($content, $pattern).Count
            if($matchcount -gt 0)
            {
                $content = [regex]::Replace($content, $pattern, $replace)
                $this.AddLog("Replaced $matchcount place(s) of $pattern with $replace", $this.logFile)
            }
        }
    
        $this.modifiedContent = $content
    }

    AddLog($log_msg, $log_file_path)
    {
        if (Test-Path -Path $log_file_path)
        {
            $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $message = "[$time] $log_msg"
            Add-Content $log_file_path $message
            Write-Host $log_msg
        }
    }
}

###############################
# Main script
###############################
#Initialize log
Clear-Host

if($folderPath.Length -eq 0)
{
    Log_To_File "MbNuint folder is not specified." $m_logFile
    exit
}

Out-File $m_logFile
Set-Location $folderPath

$testFiles = (Get-ChildItem $folderPath -Filter *Test* -Include *.vb, *.cs -Recurse)

foreach($testFile in $testFiles)
{
    $fileName = $testFile.Name
    Log_To_File "Found $fileName" $m_logFile

    $rawContent = (Get-Content -path $testFile.FullName -Raw)

    $parser = [SearchReplaceParser]::new()
    $parser.originContent = $rawContent
    $parser.searchReplaceTag = $searchReplaceTag
    $parser.logFile = $m_logFile
    $parser.SearchReplace()

    $cleanParser = [SearchReplaceParser]::new()
    $cleanParser.originContent = $parser.modifiedContent
    $cleanParser.searchReplaceTag = $searchCleanTag
    $cleanParser.logFile = $m_logFile
    $cleanParser.SearchReplace()

    $modifiedName = "$fileName.nu"
    Out-File $modifiedName
    Set-Content -Path $modifiedName -Value $cleanParser.modifiedContent
    Log_To_File "Saved changes to $modifiedName" $m_logFile
}


