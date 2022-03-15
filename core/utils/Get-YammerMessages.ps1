Function Get-YammerMessages{
    [cmdletbinding()]
    Param(
        [parameter(Mandatory=$true)]
        [object]$yammer_token
    )
    Begin{
        $all_msg = $null
        if($null -eq $yammer_token){
             Write-warning "Detected null authentication"
             return
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $yammer_token.access_token)
        $requestHeader = @{"Authorization" = $AuthHeader}
        #Prepare POST
        $yammerpost = '{"query":"{ inbox { threads(last: 10) { realtimeChannelId, pageInfo { hasNextPage, hasPreviousPage, startCursor, endCursor } edges { node { id databaseId telemetryId realtimeChannelId shares { totalCount } network { id } group { displayName description } hasAttachments viewerHasUnreadMessages viewerCanClose viewerLastSeenMessage { id } viewerMutationId threadStarter { id thread { id } sender { ... on User{ __typename id displayName email jobTitle isGuest network { id displayName } avatarUrlTemplate hasDefaultAvatar } } body { serializedContentState references { ... on User{ __typename id displayName email jobTitle isGuest network { id displayName } avatarUrlTemplate hasDefaultAvatar } } }	language	createdAt	updatedAt	isEdited } } cursor } pageInfo { endCursor hasNextPage } } } }"}'
    }
    Process{
        $param = @{
            Url = "https://web.yammer.com/graphql";
            Method = "Post";
            Headers = $requestHeader;
            Data = $yammerpost;
            Encoding = 'application/json';
            Content_Type = 'application/json';
            Verbose = $PSBoundParameters['Verbose']
            Debug = $PSBoundParameters['Debug']
        }
        $inbox = New-WebRequest @param
        if($null -ne $inbox -and $inbox.psobject.properties.Item('data')){
            $messages = $inbox.data.inbox.threads.edges
            $all_msg = @()
            foreach($msg in $messages){
                $body = $msg.node.threadStarter.body.serializedContentState | ConvertFrom-Json
                $message = New-Object psobject
                #Get From
                if($null -ne $msg.node.threadStarter.sender.email){
                    $message | Add-Member -MemberType NoteProperty -Name "From" -Value $msg.node.threadStarter.sender.email
                }
                if($null -ne $msg.node.group.displayName){
                    $message | Add-Member -MemberType NoteProperty -Name "To" -Value $msg.node.group.displayName
                }
                else{
                    $message | Add-Member -MemberType NoteProperty -Name "To" -Value $msg.node.threadStarter.body.references.email
                }
                $message | Add-Member -MemberType NoteProperty -Name "text" -Value ($body.blocks | Select-Object -ExpandProperty text)
                $message | Add-Member -MemberType NoteProperty -Name "hasAttachments" -Value $msg.node.hasAttachments
                $all_msg +=$message
            }
        }
        else{
            if($null -ne $inbox -and $inbox.errors){
                Write-Warning $inbox.errors[0].message
            }
        }
    }
    End{
        if($all_msg){
            $all_msg
        }
        else{
            Write-Warning ("Unable to get inbox messages from Yammer")          
        }
    }
}