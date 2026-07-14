/**
 * A basic controller for fetching NavigationMenuItems.
 */
global without sharing class GcHeaderNavigationMenuController {
   
    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.NavigationMenuItem> getNavigationMenuItems(String navigationLinkSetMasterLabel, String publishStatus,
            Boolean addHomeMenuItem, Boolean includeImageUrl) {
        //System.assert(navigationLinkSetMasterLabel != null);
        String navigationLinkSetDeveloperName = getNavigationLinkSetDeveloperName(navigationLinkSetMasterLabel);

        //System.assert(publishStatus != null);
        /*System.assert(publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Live.name())
            || publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Draft.name()));
 		 */
        ConnectApi.PublishStatus publishStatusEnum;
              
                
        if (publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Draft.name())) {
            publishStatusEnum = ConnectApi.PublishStatus.Draft;
        } else {
            publishStatusEnum = ConnectApi.PublishStatus.Live;
        }

        // Exclude any types that aren't supported for your navigation menu
        List<ConnectApi.NavigationMenuItemType> menuItemsToSkip = new List<ConnectApi.NavigationMenuItemType>{
            ConnectApi.NavigationMenuItemType.Event, // not supported in custom component nav menus
            ConnectApi.NavigationMenuItemType.SystemLink // not supported in nav menus
        };

        String navigationLinkSetId = null; // must provide the API the navigationLinkSetId or navigationLinkSetDeveloperName, but not both

        String networkId = '';
        
        if (Test.isRunningTest()) {
            networkId = [ select NetworkId from NetworkMember where MemberId =  :UserInfo.getUserId() limit 1 ].NetworkId;
            
            return null;
        }else{
            networkId = Network.getNetworkId();
            
            //System.assert(networkId != null);
            
            // Connect API: https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_navigation_menu_items.htm
            ConnectApi.NavigationMenuItemCollection menu = ConnectApi.NavigationMenu.getCommunityNavigationMenu(networkId,navigationLinkSetId, navigationLinkSetDeveloperName, publishStatusEnum,includeImageUrl, addHomeMenuItem, menuItemsToSkip);
            
            List<ConnectApi.NavigationMenuItem> items = menu.menuItems;
            return items;
            
            
        }
        
       
    }
    
    /**
     * Look up the DeveloperName of the NavigationLinkSet based on the provided
     * MasterLabel (aka menu name) and the NetworkId of the current context.
     * 
     * @param navigationLinkSetMasterLabel the menu name (NavigationLinkSet.MasterLabel)
     * @return the navigation linkset DeveloperName
     */
    public static String getNavigationLinkSetDeveloperName(String navigationLinkSetMasterLabel) {
        
        String networkId = '';
        
        if (Test.isRunningTest()) {
            networkId = [ select NetworkId from NetworkMember where MemberId =  :UserInfo.getUserId() limit 1 ].NetworkId;
        }else{
            networkId = Network.getNetworkId();
        }
        
         system.debug('networkId: ' + networkId);
         system.debug('navigationLinkSetMasterLabel: ' + navigationLinkSetMasterLabel);
        
        //System.assert(networkId != null);
        
        List<NavigationLinkSet> navigationLinkSets = [
            SELECT DeveloperName,Id,MasterLabel,NetworkId 
            FROM NavigationLinkSet
            WHERE NetworkId = :networkId
            AND MasterLabel = :navigationLinkSetMasterLabel
            LIMIT 1
        ];

        //System.assert(navigationLinkSets.size() == 1);
        NavigationLinkSet navigationLinkSet = navigationLinkSets.get(0);
        return navigationLinkSet.DeveloperName;
    }
}