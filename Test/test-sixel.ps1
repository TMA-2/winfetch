function Get-SixelImageDimensions {
    param (
        [string]$SixelImagePath
    )

    # Read the Sixel image content
    $SixelImageContent = Get-Content -Path $SixelImagePath -Raw

    # Initialize dimensions
    $Width = 0
    $Height = 0

    # Parse the Sixel image content to determine dimensions
    if ($SixelImageContent -match "(\x1bPq.*?\x1b\\)") {
        $SixelData = $matches[1]

        # Extract width and height from Sixel data
        if ($SixelData -match "(\d+);(\d+)") {
            $Width = [int]$matches[1]
            $Height = [int]$matches[2]
        }
    }

    return [PSCustomObject]@{
        Width = $Width
        Height = $Height
    }
}

# Define the path to the Sixel image
$SixelImagePath = "path/to/image.sixel"

# Read the Sixel image content
$SixelImageContent = Get-Content -Path $SixelImagePath -Raw

# Get the dimensions of the Sixel image
$ImageDimensions = Get-SixelImageDimensions -SixelImagePath $SixelImagePath

# Calculate the size in terms of console rows and columns
$ConsoleWidth = [math]::Ceiling($ImageDimensions.Width / 8) + 2
$ConsoleHeight = [math]::Ceiling($ImageDimensions.Height / 16)

# Display the Sixel image
Write-Output $SixelImageContent

# move cursor to top of image and to its right
[console]::SetCursorPosition($ConsoleWidth, 0)
# Scroll image up
# [console]::MoveBufferArea(0, 0, $COLUMNS, $img.Length, 0, 1)
[console]::MoveBufferArea(0, 0, $ConsoleWidth, $ConsoleHeight, $ConsoleWidth+2, 1)
<# console.MoveBufferArea()
    int sourceLeft, # leftmost column of source area
    int sourceTop, # topmost row of source area
    int sourceWidth, # number of columns in source area
    int sourceHeight, # number of rows in source area
    int targetLeft, # leftmost column of the destination
    int targetTop # topmost row of the column)
#>

<# alternately, use VT escape codes
# see: https://espterm.github.io/docs/VT100%20escape%20codes.html
# ^[D to move/scroll window up one line
# ^[xS to scroll window up x lines
# ^[xA to move cursor up x lines
#   $img.Length - [Console]::WindowHeight / [Console]::BufferHeight
#>

# Display more ASCII text
Write-Output "Here is more ASCII text after the image."
