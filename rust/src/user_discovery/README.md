


 // **Store** promotions:
 // version_id, contact_id, Option<UserDiscoveryMessage>
 // -> In case a contact_id deleted his account deleted or was removed
 //    - Remove the previous row (version_id must be increased...)
 //    - Create a new entry with User Discovery Recall
 // -> Otherwise this promotion contains the Promotion
 //