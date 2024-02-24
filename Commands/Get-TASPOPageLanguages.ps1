
function Get-TASPOPageLanguages {
    param ( [Parameter(Mandatory=$true)][int]$PageID ) 

    <#
        .SYNOPSIS
        This command retrieves all language versions of a specific SharePoint Online page.

        .DESCRIPTION
        The Get-TASPOPageLanguages command connects to a SharePoint Online site and retrieves all language versions of a specific page in the Site Pages library. The page is identified by its ID.
        For information read the blog post at https://blog.topedia.com/?p=36061.

        .PARAMETER PageID
        An integer that specifies the ID of the page to retrieve. This is a mandatory parameter.

        .EXAMPLE
        Get-TASPOPageLanguages -PageID 123

        This example retrieves all language versions of the page with ID 123.

        .NOTES
        Before running this command, you must connect to your SharePoint Online site using Connect-PnPOnline. If a connection has not been established, the command will return an error.
        The command returns an array of custom objects, each representing a language version of the page. Each object includes the following properties: ID, IsTranslation, Language, Title, and RelativeUrl.

        Author: Tobias Asböck - https://www.linkedin.com/in/tobiasasboeck
        Last updated: 24.02.2024
        
    #>

    try {
        $SitePageLibrary = Get-PnPList | ?{$_.EntityTypeName -eq "SitePages" }
    }
    catch {
        # If an error occurs (usually because Connect-PnPOnline has not been called), write an error message and return
        Write-Error "Connect-PnPOnline must be called first." ; return
    }    
    
    # Get all list items from the Site Pages library
    $AllListItems = Get-PnPListItem -List $SitePageLibrary -PageSize 1000

    # Find the list item with the specified page ID
    $ListItem = ($AllListItems | ?{$_.FieldValues.ID -eq $PageID }).FieldValues

    # If no list item with the specified ID is found, write an error message and return
    if($ListItem.Count -eq 0) { Write-Error "Page with ID $PageID not found." ; return }

    # Initialize an array to hold all pages and retrieve the source item and all translations if the list item has translations or is a translation itself
    $AllPages = @()
    if( $ListItem._SPTranslatedLanguages.Count -gt 0 -or $ListItem._SPIsTranslation -eq $true )
    { 
        # If the list item is not a translation, use its unique ID; otherwise, use the unique ID of the source item
        if( $ListItem._SPTranslationSourceItemId.Guid -eq $null )
        { $ListItemGuid = $ListItem.UniqueId.Guid } else
        {   $ListItem =  $AllListItems.FieldValues | ?{$_.UniqueId.Guid -eq $ListItem._SPTranslationSourceItemId.Guid } 
            $ListItemGuid = $ListItem.UniqueId.Guid         
        }

        $AllPages += $ListItem
        $AllPages += $AllListItems.FieldValues | ?{$_._SPTranslationSourceItemId.Guid -eq $ListItemGuid }   
    } else { 
        # If the list item has no translations and is not a translation, add it to the array
        $AllPages += $ListItem 
    }           

    # Initialize an array to hold the language pages and loop through all pages
    $LanguagePages = @()
    foreach ($Item in $AllPages)
    {   
        # Add a custom object representing the page to the array
        $LanguagePages += [PSCustomObject]@{
            'ID' = $Item.ID
            'IsTranslation' = $Item._SPIsTranslation
            'Language' = $Item._SPTranslationLanguage                
            'Title' = $Item.Title
            'RelativeUrl' = $Item.FileRef                     
        }    
    }

    return $LanguagePages  
    
}

