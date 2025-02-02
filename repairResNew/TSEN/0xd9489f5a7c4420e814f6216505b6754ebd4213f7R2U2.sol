pragma solidity ^0.4.18;
contract Ownable {
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() public {
	owner = msg.sender;
	}
	modifier onlyOwner(){
	require(msg.sender == owner);
	_;}
	function transferOwnership(address newOwner) onlyOwner public {
	require(newOwner != address(0));
	OwnershipTransferred(owner, newOwner);
	owner = newOwner;
	}
	
}library SafeMath {
	function mul(uint256 a, uint256 b) pure internal returns(uint256 ){
	if(a == 0){
	return 0;
	}
	uint256 c = a * b;
	assert(c / a == b);
	return c;
	}
	function div(uint256 a, uint256 b) pure internal returns(uint256 ){
	uint256 c = a / b;
	return c;
	}
	function sub(uint256 a, uint256 b) pure internal returns(uint256 ){
	assert(b <= a);
	return a - b;
	}
	function add(uint256 a, uint256 b) pure internal returns(uint256 ){
	uint256 c = a + b;
	assert(c >= a);
	return c;
	}
	
}contract ERC20Basic {
	function totalSupply() view public returns(uint256 );function balanceOf(address who) view public returns(uint256 );function transfer(address to, uint256 value) public returns(bool );event Transfer(address indexed from, address indexed to, uint256 value);
	
}contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) view public returns(uint256 );function transferFrom(address from, address to, uint256 value) public returns(bool );function approve(address spender, uint256 value) public returns(bool );event Approval(address indexed owner, address indexed spender, uint256 value);
	
}contract ERC827 is ERC20 {
	function approve(address _spender, uint256 _value, bytes _data) public returns(bool );function transfer(address _to, uint256 _value, bytes _data) public returns(bool );function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns(bool );
}contract BasicToken is ERC20Basic {
	using SafeMath for uint256;
	mapping(address => uint256) balances;
	uint256 totalSupply_;
	function totalSupply() view public returns(uint256 ){
	return totalSupply_;
	}
	function transfer(address _to, uint256 _value) public returns(bool ){
	require(_to != address(0));
	require(_value <= balances[msg.sender]);
	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	Transfer(msg.sender, _to, _value);
	return true;
	}
	function balanceOf(address _owner) view public returns(uint256 balance){
	return balances[_owner];
	}
	
}contract StandardToken is ERC20 , BasicToken {
	mapping(address => mapping(address => uint256)) allowed;
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool ){
	require(_to != address(0));
	require(_value <= balances[_from]);
	require(_value <= allowed[_from][msg.sender]);
	balances[_from] = balances[_from].sub(_value);
	balances[_to] = balances[_to].add(_value);
	allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	Transfer(_from, _to, _value);
	return true;
	}
	function approve(address _spender, uint256 _value) public returns(bool ){
	allowed[msg.sender][_spender] = _value;
	Approval(msg.sender, _spender, _value);
	return true;
	}
	function allowance(address _owner, address _spender) view public returns(uint256 ){
	return allowed[_owner][_spender];
	}
	function increaseApproval(address _spender, uint _addedValue) public returns(bool ){
	allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	return true;
	}
	function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool ){
	uint oldValue = allowed[msg.sender][_spender];
	if(_subtractedValue > oldValue){
	allowed[msg.sender][_spender] = 0;
	}
	else{
	allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	}
	Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	return true;
	}
	
}contract ERC827Token is ERC827 , StandardToken {
	function approve(address _spender, uint256 _value, bytes _data) public returns(bool ){
	require(_spender != address(this));
	super.approve(_spender, _value);
	require(_spender.call(_data));
	return true;
	}
	function transfer(address _to, uint256 _value, bytes _data) public returns(bool ){
	require(_to != address(this));
	super.transfer(_to, _value);
	require(_to.call(_data));
	return true;
	}
	function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns(bool ){
	require(_to != address(this));
	super.transferFrom(_from, _to, _value);
	require(_to.call(_data));
	return true;
	}
	function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns(bool ){
	require(_spender != address(this));
	super.increaseApproval(_spender, _addedValue);
	require(_spender.call(_data));
	return true;
	}
	function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns(bool ){
	require(_spender != address(this));
	super.decreaseApproval(_spender, _subtractedValue);
	require(_spender.call(_data));
	return true;
	}
	
}contract MintableToken is StandardToken , Ownable {
	event Mint(address indexed to, uint256 amount);
	event MintFinished();
	bool public mintingFinished = false;
	modifier canMint(){
	require(! mintingFinished);
	_;}
	function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool ){
	totalSupply_ = totalSupply_.add(_amount);
	balances[_to] = balances[_to].add(_amount);
	Mint(_to, _amount);
	Transfer(address(0), _to, _amount);
	return true;
	}
	function finishMinting() onlyOwner canMint public returns(bool ){
	mintingFinished = true;
	MintFinished();
	return true;
	}
	
}contract Pausable is Ownable {
	event Pause();
	event Unpause();
	bool public paused = false;
	modifier whenNotPaused(){
	require(! paused);
	_;}
	modifier whenPaused(){
	require(paused);
	_;}
	function pause() onlyOwner whenNotPaused public {
	paused = true;
	Pause();
	}
	function unpause() onlyOwner whenPaused public {
	paused = false;
	Unpause();
	}
	
}contract PausableToken is StandardToken , Pausable {
	function transfer(address _to, uint256 _value) whenNotPaused public returns(bool ){
	return super.transfer(_to, _value);
	}
	function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns(bool ){
	return super.transferFrom(_from, _to, _value);
	}
	function approve(address _spender, uint256 _value) whenNotPaused public returns(bool ){
	return super.approve(_spender, _value);
	}
	function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns(bool success){
	return super.increaseApproval(_spender, _addedValue);
	}
	function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns(bool success){
	return super.decreaseApproval(_spender, _subtractedValue);
	}
	
}contract LifToken is StandardToken , ERC827Token , MintableToken , PausableToken {
	string public constant NAME = "Líf";
	string public constant SYMBOL = "LIF";
	uint public constant DECIMALS = 18;
	function burn(uint256 _value) whenNotPaused public {
	require(_value <= balances[msg.sender]);
	balances[msg.sender] = balances[msg.sender].sub(_value);
	totalSupply_ = totalSupply_.sub(_value);
	Transfer(msg.sender, address(0), _value);
	}
	function burn(address burner, uint256 _value) onlyOwner public {
	require(! mintingFinished);
	require(_value <= balances[burner]);
	balances[burner] = balances[burner].sub(_value);
	totalSupply_ = totalSupply_.sub(_value);
	Transfer(burner, address(0), _value);
	}
	
}contract VestedPayment is Ownable {
	using SafeMath for uint256;
	uint256 public startTimestamp;
	uint256 public secondsPerPeriod;
	uint256 public totalPeriods;
	uint256 public tokens;
	uint256 public claimed;
	LifToken public token;
	uint256 public cliffDuration;
	constructor(uint256 _startTimestamp, uint256 _secondsPerPeriod, uint256 _totalPeriods, uint256 _cliffDuration, uint256 _tokens, address tokenAddress) public {
	require(_startTimestamp >= block.timestamp);
	require(_secondsPerPeriod > 0);
	require(_totalPeriods > 0);
	require(tokenAddress != address(0));
	require(_cliffDuration < _totalPeriods);
	require(_tokens > 0);
	startTimestamp = _startTimestamp;
	secondsPerPeriod = _secondsPerPeriod;
	totalPeriods = _totalPeriods;
	cliffDuration = _cliffDuration;
	tokens = _tokens;
	token = LifToken(tokenAddress);
	}
	function getAvailableTokens() view public returns(uint256 ){
	uint256 period = block.timestamp.sub(startTimestamp).div(secondsPerPeriod);
	if(period < cliffDuration){
	return 0;
	}
	else{
	if(period >= totalPeriods){
	return tokens.sub(claimed);
	}
	else{
	return tokens.mul(period.add(1)).div(totalPeriods).sub(claimed);
	}
	}
	}
	function claimTokens(uint256 amount) onlyOwner public {
	assert(getAvailableTokens() >= amount);
	claimed = claimed.add(amount);
	token.transfer(owner, amount);
	}
	
}contract LifMarketValidationMechanism is Ownable {
	using SafeMath for uint256;
	LifToken public lifToken;
	address public foundationAddr;
	uint256 public initialWei;
	uint256 public startTimestamp;
	uint256 public secondsPerPeriod;
	uint8 public totalPeriods;
	uint256 public totalWeiClaimed = 0;
	uint256 public initialBuyPrice = 0;
	uint256 public totalBurnedTokens = 0;
	uint256 public totalReimbursedWei = 0;
	uint256 public originalTotalSupply;
	uint256 constant PRICE_FACTOR = 100000;
	bool public funded = false;
	bool public paused = false;
	uint256 public totalPausedSeconds = 0;
	uint256 public pausedTimestamp;
	uint256[] public periods;
	event Pause();
	event Unpause(uint256 pausedSeconds);
	event ClaimedWei(uint256 claimedWei);
	event SentTokens(address indexed sender, uint256 price, uint256 tokens, uint256 returnedWei);
	modifier whenNotPaused(){
	assert(! paused);
	_;}
	modifier whenPaused(){
	assert(paused);
	_;}
	constructor(address lifAddr, uint256 _startTimestamp, uint256 _secondsPerPeriod, uint8 _totalPeriods, address _foundationAddr) public {
	require(lifAddr != address(0));
	require(_startTimestamp > block.timestamp);
	require(_secondsPerPeriod > 0);
	require(_totalPeriods == 24 || _totalPeriods == 48);
	require(_foundationAddr != address(0));
	lifToken = LifToken(lifAddr);
	startTimestamp = _startTimestamp;
	secondsPerPeriod = _secondsPerPeriod;
	totalPeriods = _totalPeriods;
	foundationAddr = _foundationAddr;
	}
	function fund() onlyOwner payable public {
	assert(! funded);
	initialWei = msg.value;
	initialBuyPrice = initialWei.mul(PRICE_FACTOR).div(originalTotalSupply);
	funded = true;
	originalTotalSupply = lifToken.totalSupply();
	}
	function calculateDistributionPeriods() public {
	assert(totalPeriods == 24 || totalPeriods == 48);
	assert(periods.length == 0);
	uint256[24] memory accumDistribution24 = [uint256(0),18,117,351,767,1407,2309,3511,5047,6952,9257,11995,15196,18889,23104,27870,33215,39166,45749,52992,60921,69561,78938,89076];
	uint256[48] memory accumDistribution48 = [uint256(0),3,18,54,117,214,351,534,767,1056,1406,1822,2308,2869,3510,4234,5046,5950,6950,8051,9256,10569,11994,13535,15195,16978,18888,20929,23104,25416,27870,30468,33214,36112,39165,42376,45749,49286,52992,56869,60921,65150,69560,74155,78937,83909,89075,94438];
	for(uint8 i = 0;i < totalPeriods;i++){
	if(totalPeriods == 24){
	periods.push(accumDistribution24[i]);
	}
	else{
	periods.push(accumDistribution48[i]);
	}
	}
	}
	function getCurrentPeriodIndex() view public returns(uint256 ){
	assert(block.timestamp >= startTimestamp);
	return block.timestamp.sub(startTimestamp).sub(totalPausedSeconds).div(secondsPerPeriod);
	}
	function getAccumulatedDistributionPercentage() view public returns(uint256 percentage){
	uint256 period = getCurrentPeriodIndex();
	assert(period < totalPeriods);
	return periods[period];
	}
	function getBuyPrice() view public returns(uint256 price){
	uint256 accumulatedDistributionPercentage = getAccumulatedDistributionPercentage();
	return initialBuyPrice.mul(PRICE_FACTOR.sub(accumulatedDistributionPercentage)).div(PRICE_FACTOR);
	}
	function getMaxClaimableWeiAmount() view public returns(uint256 ){
	if(isFinished()){
	return this.balance;
	}
	else{
	uint256 claimableFromReimbursed = initialBuyPrice.mul(totalBurnedTokens).div(PRICE_FACTOR).sub(totalReimbursedWei);
	uint256 currentCirculation = lifToken.totalSupply();
	uint256 accumulatedDistributionPercentage = getAccumulatedDistributionPercentage();
	uint256 maxClaimable = initialWei.mul(accumulatedDistributionPercentage).div(PRICE_FACTOR).mul(currentCirculation).div(originalTotalSupply).add(claimableFromReimbursed);
	if(maxClaimable > totalWeiClaimed){
	return maxClaimable.sub(totalWeiClaimed);
	}
	else{
	return 0;
	}
	}
	}
	function sendTokens(uint256 tokens) whenNotPaused public {
	require(tokens > 0);
	uint256 price = getBuyPrice();
	uint256 totalWei = tokens.mul(price).div(PRICE_FACTOR);
	lifToken.transferFrom(msg.sender, address(this), tokens);
	lifToken.burn(tokens);
	totalBurnedTokens = totalBurnedTokens.add(tokens);
	SentTokens(msg.sender, price, tokens, totalWei);
	totalReimbursedWei = totalReimbursedWei.add(totalWei);
	msg.sender.transfer(totalWei);
	}
	function isFinished() view public returns(bool finished){
	return getCurrentPeriodIndex() >= totalPeriods;
	}
	function claimWei(uint256 weiAmount) whenNotPaused public {
	require(msg.sender == foundationAddr);
	foundationAddr.transfer(weiAmount);
	totalWeiClaimed = totalWeiClaimed.add(weiAmount);
	uint256 claimable = getMaxClaimableWeiAmount();
	assert(claimable >= weiAmount);
	ClaimedWei(weiAmount);
	}
	function pause() onlyOwner whenNotPaused public {
	paused = true;
	pausedTimestamp = block.timestamp;
	Pause();
	}
	function unpause() onlyOwner whenPaused public {
	uint256 pausedSeconds = block.timestamp.sub(pausedTimestamp);
	totalPausedSeconds = totalPausedSeconds.add(pausedSeconds);
	paused = false;
	Unpause(pausedSeconds);
	}
	
}contract LifCrowdsale is Ownable , Pausable {
	using SafeMath for uint256;
	LifToken public token;
	uint256 public startTimestamp;
	uint256 public end1Timestamp;
	uint256 public end2Timestamp;
	address public foundationWallet;
	address public foundersWallet;
	uint256 public minCapUSD = 5000000;
	uint256 public maxFoundationCapUSD = 10000000;
	uint256 public MVM24PeriodsCapUSD = 40000000;
	uint256 public weiPerUSDinTGE = 0;
	uint256 public setWeiLockSeconds = 0;
	uint256 public rate1;
	uint256 public rate2;
	uint256 public weiRaised;
	uint256 public tokensSold;
	VestedPayment public foundationVestedPayment;
	VestedPayment public foundersVestedPayment;
	LifMarketValidationMechanism public MVM;
	mapping(address => uint256) public purchases;
	bool public isFinalized = false;
	event Finalized();
	event TokenPresalePurchase(address indexed beneficiary, uint256 weiAmount, uint256 rate);
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	constructor(uint256 _startTimestamp, uint256 _end1Timestamp, uint256 _end2Timestamp, uint256 _rate1, uint256 _rate2, uint256 _setWeiLockSeconds, address _foundationWallet, address _foundersWallet) public {
	require(_startTimestamp > block.timestamp);
	require(_end1Timestamp > _startTimestamp);
	require(_end2Timestamp > _end1Timestamp);
	require(_rate1 > 0);
	require(_rate2 > 0);
	require(_setWeiLockSeconds > 0);
	require(_foundationWallet != address(0));
	require(_foundersWallet != address(0));
	token = new LifToken();
	token.pause();
	startTimestamp = _startTimestamp;
	end1Timestamp = _end1Timestamp;
	end2Timestamp = _end2Timestamp;
	rate1 = _rate1;
	rate2 = _rate2;
	setWeiLockSeconds = _setWeiLockSeconds;
	foundationWallet = _foundationWallet;
	foundersWallet = _foundersWallet;
	}
	function setWeiPerUSDinTGE(uint256 _weiPerUSD) onlyOwner public {
	require(_weiPerUSD > 0);
	assert(block.timestamp < startTimestamp.sub(setWeiLockSeconds));
	weiPerUSDinTGE = _weiPerUSD;
	}
	function getRate() view public returns(uint256 ){
	if(block.timestamp < startTimestamp){
	return 0;
	}
	else{
	if(block.timestamp <= end1Timestamp){
	return rate1;
	}
	else{
	if(block.timestamp <= end2Timestamp){
	return rate2;
	}
	else{
	return 0;
	}
	}
	}
	}
	function () payable public {
	buyTokens(msg.sender);
	}
	function buyTokens(address beneficiary) whenNotPaused validPurchase payable public {
	require(beneficiary != address(0));
	assert(weiPerUSDinTGE > 0);
	uint256 weiAmount = msg.value;
	uint256 rate = getRate();
	assert(rate > 0);
	uint256 tokens = weiAmount.mul(rate);
	weiRaised = weiRaised.add(weiAmount);
	purchases[beneficiary] = purchases[beneficiary].add(weiAmount);
	tokensSold = tokensSold.add(tokens);
	token.mint(beneficiary, tokens);
	TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
	}
	function addPrivatePresaleTokens(address beneficiary, uint256 weiSent, uint256 rate) onlyOwner public {
	require(block.timestamp < startTimestamp);
	require(beneficiary != address(0));
	require(weiSent > 0);
	require(rate > rate1);
	uint256 tokens = weiSent.mul(rate);
	weiRaised = weiRaised.add(weiSent);
	token.mint(beneficiary, tokens);
	TokenPresalePurchase(beneficiary, weiSent, rate);
	}
	function forwardFunds() internal {
	uint256 foundationBalanceCapWei = maxFoundationCapUSD.mul(weiPerUSDinTGE);
	if(weiRaised <= foundationBalanceCapWei){
	foundationWallet.transfer(this.balance);
	mintExtraTokens(uint256(24));
	}
	else{
	uint256 mmFundBalance = this.balance.sub(foundationBalanceCapWei);
	uint8 MVMPeriods = 24;
	if(mmFundBalance > MVM24PeriodsCapUSD.mul(weiPerUSDinTGE)){
	MVMPeriods = 48;
	}
	foundationWallet.transfer(foundationBalanceCapWei);
	MVM = new LifMarketValidationMechanism(address(token), block.timestamp.add(30 minutes), 10 minutes, MVMPeriods, foundationWallet);
	MVM.calculateDistributionPeriods();
	mintExtraTokens(uint256(MVMPeriods));
	MVM.fund.value(mmFundBalance)();
	MVM.transferOwnership(foundationWallet);
	}
	}
	function mintExtraTokens(uint256 foundationMonthsStart) internal {
	uint256 foundersTokens = token.totalSupply().mul(128).div(1000);
	uint256 foundationTokens = token.totalSupply().mul(50).div(1000);
	uint256 teamTokens = token.totalSupply().mul(72).div(1000);
	foundersVestedPayment = new VestedPayment(block.timestamp, 10 minutes, 48, 12, foundersTokens, token);
	token.mint(foundersVestedPayment, foundersTokens);
	foundersVestedPayment.transferOwnership(foundersWallet);
	uint256 foundationPaymentStart = foundationMonthsStart.mul(10 minutes).add(30 minutes);
	foundationVestedPayment = new VestedPayment(block.timestamp.add(foundationPaymentStart), 10 minutes, foundationMonthsStart, 0, foundationTokens, token);
	token.mint(foundationVestedPayment, foundationTokens);
	foundationVestedPayment.transferOwnership(foundationWallet);
	token.mint(foundationWallet, teamTokens);
	}
	modifier validPurchase(){
	bool withinPeriod = now >= startTimestamp && now <= end2Timestamp;
	bool nonZeroPurchase = msg.value != 0;
	assert(withinPeriod && nonZeroPurchase);
	_;}
	modifier hasEnded(){
	assert(block.timestamp > end2Timestamp);
	_;}
	function funded() view public returns(bool ){
	assert(weiPerUSDinTGE > 0);
	return weiRaised >= minCapUSD.mul(weiPerUSDinTGE);
	}
	function claimEth() whenNotPaused hasEnded public {
	require(isFinalized);
	require(! funded());
	uint256 toReturn = purchases[msg.sender];
	assert(toReturn > 0);
	purchases[msg.sender] = 0;
	msg.sender.transfer(toReturn);
	}
	function returnPurchase(address contributor) hasEnded onlyOwner public {
	require(! isFinalized);
	uint256 toReturn = purchases[contributor];
	assert(toReturn > 0);
	weiRaised = weiRaised.sub(toReturn);
	tokensSold = tokensSold.sub(tokenBalance);
	token.burn(contributor, tokenBalance);
	purchases[contributor] = 0;
	uint256 tokenBalance = token.balanceOf(contributor);
	contributor.transfer(toReturn);
	}
	function finalize() onlyOwner hasEnded public {
	require(! isFinalized);
	if(funded()){
	token.finishMinting();
	token.transferOwnership(owner);
	forwardFunds();
	}
	Finalized();
	isFinalized = true;
	}
	
}