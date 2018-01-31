pragma solidity ^0.4.18;

contract AnimalFactory {
    //Events
    event GaveBirth(address owner, uint256 animalId, uint256 fatherId, uint256 motherId, string genes);
    event AnimalMated(uint indexed animalIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event AnimalOffered(uint indexed animalIndex, uint minValue, address indexed toAddress);
    event AnimalTransfer(address from, address to, uint256 tokenId);
    event AnimalBidEntered(uint indexed animalIndex, uint value, address indexed fromAddress);
    event AnimalBought(uint indexed animalIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event AnimalNoLongerForSale(uint indexed animalIndex);
    event AnimalNoLongerForMating(uint indexed animalIndex);
    event AnimalBidWithdrawn(uint indexed animalIndex, uint value, address indexed fromAddress);
    event AnimalOfferedForMating(uint indexed animalIndex, uint minValue, address indexed toAddress);

    //Public variable
    bool public claimable = true;
    uint256 public totalAnimalCount = 0;

    //Private
    address public owner;

    struct Animal {
                    string genes;
                    uint64 birthTime;
                    uint32 motherId;
                    uint32 fatherId;
                    uint16 pregnant;
                    uint16 generation;
                    address firstowner;
                    uint16 eggphase;
                    string name;
                    string bio;
    }
    Animal[] animals;

    struct Offer {
                    bool isForSale;
                    uint animalIndex;
                    address seller;
                    uint minValue;          // in ether
                    address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
                    bool hasBid;
                    uint animalIndex;
                    address bidder;
                    uint value;
    }

    //Mapping
    //mapping (uint256 => address) public animalIndexApproved;
    //mapping (uint256 => address) public matingAllowedToAddress;
    // which animal belongs to who
    mapping (uint256 => address) public animalOwnerIndex; //!!!
    mapping (address => uint256) public ownerTokenCount;  //!!!
    // A record of the highest animal bid
    mapping (uint => Bid) public animalBids; //!!!
    // A record of animals that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public animalsOfferedForSale; //!!!
    // A record of animals that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public animalsOfferedForMating;
    mapping (address => uint) public pendingWithdrawals;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function AnimalFactory(address _owner) public {
        owner = _owner;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function transferAnimal(address _from, address _to, uint256 _tokenId) internal {
        ownerTokenCount[_to]++;
        //token id is animal id, key value pair
        animalOwnerIndex[_tokenId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownerTokenCount[_from]--;
            // once the kitten is transferred also clear sire allowances
            delete animalsOfferedForMating[_tokenId];
            delete animalsOfferedForSale[_tokenId];
        }
        // Emit the transfer event.
        AnimalTransfer(_from, _to, _tokenId);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function balanceOf(address _owner) internal view returns (uint256 count) {
        return ownerTokenCount[_owner];
    }

    // ###########################################################
    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 animalId;
            for (animalId = 1; animalId <= totalAnimalCount; animalId++) {
                if (animalOwnerIndex[animalId] == _owner) {
                    result[resultIndex] = animalId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    // ###########################################################
    function claimAnimal() public {
        //check if claimable on ? if on allow
        require(claimable);
        //when you claim a animal set geneid
        //also check if it is not locked
        createAnimal(0, 0, 1, "0", msg.sender, 1);
    }

    // ###########################################################
    function setNameBio(uint256 _tokenId, string name, string bio) public {
        Animal storage bunny = animals[_tokenId];
        bunny.name = name;
        bunny.bio = bio;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function createAnimal(uint256 _motherId, uint256 _fatherId, uint256 _generation, string _genes,
                            address _owner, uint16 _eggphase) internal returns (uint)
    {
        //only admin can create Animal
        //or if it was a mated
        Animal memory _animal = Animal({
                                    genes : _genes,
                                    birthTime : uint64(now),
                                    motherId : uint32(_motherId),
                                    fatherId : uint32(_fatherId),
                                    pregnant : 0,
                                    generation : uint16(_generation),
                                    firstowner : _owner,
                                    eggphase : _eggphase,
                                    name : "",
                                    bio : ""
        });
        uint256 newAnimalId = animals.push(_animal) - 1;
        totalAnimalCount++;
        ownerTokenCount[_owner]++;
        // emit the birth event
        GaveBirth(_owner, newAnimalId, uint256(_animal.fatherId), uint256(_animal.motherId), _animal.genes);
        //add animal to ownership
        animalOwnerIndex[newAnimalId] = _owner;
        AnimalTransfer(0, _owner, newAnimalId);
        return newAnimalId;
    }

    // ###########################################################
    function getAnimal(uint256 _id) external view returns (
                uint256 birthTime,
                uint256 motherId,
                uint256 fatherId,
                uint256 generation,
                //uint256 pregnant,
                //uint256 donorId,
                string genes,
                string name,
                string bio
    ) {
        Animal storage bunny = animals[_id];
        birthTime = uint256(bunny.birthTime);
        motherId = uint256(bunny.motherId);
        fatherId = uint256(bunny.fatherId);
        generation = uint256(bunny.generation);
        genes = bunny.genes;
        name = bunny.name;
        bio = bunny.bio;
    }

    // ###########################################################
    function isAvailableforMating(uint256 _tokenId, uint minSalePriceInWei) public {
        require(animalOwnerIndex[_tokenId] == msg.sender);
        animalsOfferedForMating[_tokenId] = Offer(true, _tokenId, msg.sender, minSalePriceInWei, 0x0);
        AnimalOfferedForMating(_tokenId, minSalePriceInWei, 0x0);
    }

    // ###########################################################
    function animalNoLongerForMating(uint animalIndex) public {
        require(animalOwnerIndex[animalIndex] == msg.sender);
        animalsOfferedForMating[animalIndex] = Offer(false, animalIndex, msg.sender, 0, 0x0);
        AnimalNoLongerForSale(animalIndex);
    }

    ///accept mating
    ///pay the mater then create new animal set eggphase to 0x0
    //send 10% to company
    // ###########################################################
    function acceptAnimalMating(uint animalIndex) public payable {
        ///get the materid
        Offer storage offer = animalsOfferedForMating[animalIndex];

        require(offer.isForSale);
        // animal not actually for sale
        require(offer.onlySellTo == 0x0 && offer.onlySellTo == msg.sender);
        // animal not supposed to be sold to this user
        require(msg.value > offer.minValue);
        // Didn't send enough ETH
        require(offer.seller == animalOwnerIndex[animalIndex]);
        // Seller no longer owner of animal

        address seller = offer.seller;
        //eggphase = 0 means not created
        createAnimal(0, 0, 1, "ABC", msg.sender, 0);
        pendingWithdrawals[seller] += msg.value;
        AnimalMated(animalIndex, msg.value, seller, msg.sender);
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function animalNoLongerForSale(uint animalIndex) internal {
        require(animalOwnerIndex[animalIndex] == msg.sender);
        animalsOfferedForSale[animalIndex] = Offer(false, animalIndex, msg.sender, 0, 0x0);
        AnimalNoLongerForSale(animalIndex);
    }

    // ###########################################################
    function offerAnimalForSale(uint animalIndex, uint minSalePriceInWei) public {
        require(animalOwnerIndex[animalIndex] == msg.sender);
        animalsOfferedForSale[animalIndex] = Offer(true, animalIndex, msg.sender, minSalePriceInWei, 0x0);
        AnimalOffered(animalIndex, minSalePriceInWei, 0x0);
    }

    // ###########################################################
    function offerAnimalForSaleToAddress(uint animalIndex, uint minSalePriceInWei, address toAddress) public {
        require(animalOwnerIndex[animalIndex] == msg.sender);
        animalsOfferedForSale[animalIndex] = Offer(true, animalIndex, msg.sender, minSalePriceInWei, toAddress);
        AnimalOffered(animalIndex, minSalePriceInWei, toAddress);
    }

    // ###########################################################
    function buyAnimal(uint animalIndex) payable public {
        Offer storage offer = animalsOfferedForSale[animalIndex];
        require(offer.isForSale);
        // animal not actually for sale
        require(offer.onlySellTo == 0x0 && offer.onlySellTo == msg.sender);
        // animal not supposed to be sold to this user
        require(msg.value > offer.minValue);
        // Didn't send enough ETH
        require(offer.seller == animalOwnerIndex[animalIndex]);
        // Seller no longer owner of animal
        address seller = offer.seller;
        animalOwnerIndex[animalIndex] = msg.sender;
        ownerTokenCount[seller]--;
        ownerTokenCount[msg.sender]++;
        transferAnimal(seller, msg.sender, animalIndex);
        animalNoLongerForSale(animalIndex);

        //logic to send commsion to owner
        pendingWithdrawals[seller] += msg.value;
        AnimalBought(animalIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid storage bid = animalBids[animalIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            animalBids[animalIndex] = Bid(false, animalIndex, 0x0, 0);
        }
    }

    // ###########################################################
    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    // ###########################################################
    function enterBidForAnimal(uint animalIndex) public payable {
        require(animalOwnerIndex[animalIndex] != 0x0);
        require(animalOwnerIndex[animalIndex] != msg.sender);
        require(msg.value != 0);
        Bid storage existing = animalBids[animalIndex];
        require(msg.value >= existing.value);
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        animalBids[animalIndex] = Bid(true, animalIndex, msg.sender, msg.value);
        AnimalBidEntered(animalIndex, msg.value, msg.sender);
    }

    // ###########################################################
    function acceptBidForAnimal(uint animalIndex, uint minPrice) public {
        require(animalOwnerIndex[animalIndex] == msg.sender);
        address seller = msg.sender;
        Bid storage bid = animalBids[animalIndex];
        require(bid.value != 0);
        require(bid.value > minPrice);

        animalOwnerIndex[animalIndex] = bid.bidder;
        ownerTokenCount[seller]--;
        ownerTokenCount[bid.bidder]++;

        transferAnimal(seller, bid.bidder, animalIndex);

        animalsOfferedForSale[animalIndex] = Offer(false, animalIndex, bid.bidder, 0, 0x0);
        uint amount = bid.value;
        animalBids[animalIndex] = Bid(false, animalIndex, 0x0, 0);
        pendingWithdrawals[seller] += amount;
        AnimalBought(animalIndex, bid.value, seller, bid.bidder);
    }

    // ###########################################################
    function withdrawBidForAnimal(uint animalIndex) public {
        require(animalOwnerIndex[animalIndex] != 0x0);
        require(animalOwnerIndex[animalIndex] != msg.sender);
        Bid storage bid = animalBids[animalIndex];
        require(bid.bidder == msg.sender);
        AnimalBidWithdrawn(animalIndex, bid.value, msg.sender);
        uint amount = bid.value;
        animalBids[animalIndex] = Bid(false, animalIndex, 0x0, 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }

}
