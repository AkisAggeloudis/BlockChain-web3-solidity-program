//SPDX-License-Identifier:MIT
pragma solidity >= 0.5.9;

contract Lottery_Ballot
{
    struct Person
    {
        uint personId;
        address addr;
        
    }

    struct Item
    {
        uint itemId;
        uint[] itemTokens;
    }
    
    mapping(address => Person) tokenDetails; // διεύθυνση παίκτη
    Person [] bidders; // πίνακας  παικτών
    Item [3] public items; // πίνακας 3 αντικειμένων
    address[3] public winners; // πίνακας νικητών - η τιμή 0 δηλώνει πως δεν υπάρχει νικητής
    address public beneficiary; // ο πρόεδρος του συλλόγου και ιδιοκτήτης του smart contract
    uint bidderCount = 0; // πλήθος των εγγεγραμένων παικτών
    uint timesPlayed;

    constructor() public payable //το warning εδω ειναι για το public 
    {   //constructor
        // Αρχικοποίηση του προέδρου με τη διεύθυνση του κατόχου του έξυπνου συμβολαίου
        beneficiary = msg.sender;
        uint[] memory emptyArray;
        items[0] = Item({itemId:0, itemTokens:emptyArray}); // το πρώτο αντικείμενο
        items[1] = Item({itemId:1, itemTokens:emptyArray});
        items[2] = Item({itemId:2, itemTokens:emptyArray});
        
    }

    // Ποντάρει 1 λαχεία στο αντικείμενο _itemId                   
    function bid(uint _itemId) public payable CheckEth()  
    {   
        // εγγραφή παίκτη
        bidders[bidderCount].personId = bidderCount;
        // Αρχικοποίηση της διεύθυνσης του παίκτη
        bidders[bidderCount].addr = msg.sender;
        tokenDetails[msg.sender] = bidders[bidderCount];
        
        /*
        Ενημέρωση της κληρωτίδας του _itemId με εισαγωγή των _count λαχείων που ποντάρει ο παίκτης
        */
        items[_itemId].itemTokens[_itemId] = items[_itemId].itemTokens[_itemId] + 1; 

        bidderCount++;
    }

    //random number generator
    function getRandomNumber() public view returns (uint) 
    {
        return uint(keccak256(abi.encodePacked(beneficiary, block.timestamp)));
    }

    function DeclearWinners() public onlyOwner() 
    {     
        /*
        Για κάθε αντικείμενο που έχει περισσότερα από 0 λαχεία στην κάλπη του
        επιλέξτε τυχαία έναν νικητή από όσους έχουν τοποθετήσει το λαχείο τους
        */
        for (uint id = 0; id < items.length; id++) 
        {   // Εδώ για 3 μόνο αντικείμενα
            if(items[id].itemTokens[id] > 0 )
            {
                // παραγωγή τυχαίου αριθμού
                uint index = getRandomNumber() % bidders.length;
                // ανάκτηση του αριθμού παίκτη που είχε αυτό το λαχείο
                // ενημέρωση του πίνακα winners με τη διεύθυνση του νικητή
                winners[id] = bidders[index].addr;
                emit Winner(winners[id], items[id].itemId, timesPlayed); //κανω trigger το event
            }
            else
            {
                winners[id] = address(0x0);//καταχωρείται ο αριθμός 0 (Οι παίκτες αριθμούνται από το 1).
            }
        }
    }

    function AmIWinner() public NotOwner() view returns(uint,uint,uint) 
    {   
        uint car = 0;
        uint phone = 0;
        uint pc = 0;

        for(uint id=0; id<3; id++)
        {
            if (winners[id] == msg.sender)
            {
                if(id==0)
                {
                    car = 1;
                }
                else if(id==1)
                {
                    phone = 2;
                }
                else
                {
                    pc = 3;
                }
                return(car,phone,pc);
            }
            
        }
        revert("Invalid values");
    }

    function Reveal() public view returns(uint[] memory,uint[] memory,uint[] memory)
    {
        return(items[0].itemTokens,items[1].itemTokens,items[2].itemTokens);  
    }

    function getPersonDetails(uint id) public view returns(uint, address)
    {
        return (bidders[id].personId, bidders[id].addr);
    }

    function withdraw() public payable onlyOwner() //τραβαει τα λεφτα στο πορτοφολι του
    {
       payable(beneficiary).transfer(address(this).balance);
    }

    function Reset() public payable onlyOwner() //κανουμε reset τους πινακες μας ωστε να ξανα παιξουμε
    {

        delete bidders; //reset bidders
        delete winners; //reset winners
        delete items; //reset items
        timesPlayed = timesPlayed + 1;//how many times the lottery played 
    }

    // Events
    event Winner(address Bidders, uint itemS,uint TimesPlayed );

    //modifiers
    modifier CheckEth() //check αν εχει πανω απο .01 ether 
    {
        require(msg.value >= 0 ether , "Not enough ETH");
        _; 
    }

    modifier NotOwner() //check αν δεν ειναι owner
    {
        require(msg.sender != beneficiary, "THe owner is not allowed in this phase");
        _;
    }

    modifier onlyOwner() // check αν ειναι owner
    {
        require(msg.sender == beneficiary, "Not the owner");
        _;
    }

    modifier ValidCheck(uint _itemId) //modifier για ελεγχο αν παίκτης που καλεί το αντικείμενο υπάρχει;
    {
        //require(bidders[bidderCount].remainingTokens >= 1 , "Not enough lottery tickets");
        require(items[_itemId].itemId == _itemId, "Not valid items");
        _;
    }
        
}