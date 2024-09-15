// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract FanToken is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {
    struct Proposal {
        string description;
        uint256 voteCount;
        bool executed;
        uint256 deadline;
        uint256 amount;
        bool voted;
        mapping(address userDelegante => mapping(address delegado => bool votouOuNao)) votedDelegate; //delegacao por proposta
        mapping(address => bool) hasDelegated;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    //se o endereco ja votou ou alguem votou por ele fica verdadeito

    event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
    event Voted(address indexed sender, address indexed user, uint256 proposalId, uint256 weight);
    event ProposalExecuted(uint256 proposalId);

    error AmountVote(uint256 amountProposed, uint256 amountDelegate);
    error ProposalNotDelegated();
    error AlreadyDelegate();

    constructor(address initialOwner) ERC20("FanToken", "FAN") Ownable(initialOwner) ERC20Permit("FanToken") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // Criação de novas propostas para votação
    function createProposal(string memory description, uint256 duration, uint256 amount)
        public
        onlyOwner
        returns (uint256 id)
    {
        //somando as propostas
        proposalCount++;
        //definicoes da estrutura:
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = description;
        newProposal.voteCount = 0;
        newProposal.executed = false;
        newProposal.deadline = block.timestamp + duration;
        newProposal.amount = amount;
        newProposal.voted = false;
        emit ProposalCreated(proposalCount, description, block.timestamp + duration);
        ///insira sua duracao conforme o Unix timestamp: https://www.unixtimestamp.com/
        //Exemplo: 1 Semana = 604800
        return proposalCount; //ID
    }

    //delegando seu voto: delegate - https://vscode.dev/github/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/governance/utils/Votes.sol#L127

    //a delegacao e' de acordo com o numero de tokens que o usuario possui
    function delegate(address user) public override {
        uint256 balance = _getVotingUnits(msg.sender); // Obtém o saldo de votos do usuário
        require(balance > 0, "nao possui saldo para delegar votos");

        // Checa se o usuário já delegou para qualquer proposta
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].hasDelegated[msg.sender]) {
                revert("Ja delegou votos para esta proposta");
            }
        }

        // Marca como delegada
        for (uint256 i = 1; i <= proposalCount; i++) {
            proposals[i].hasDelegated[msg.sender] = true; // Marca que o usuário já delegou
        }

        // O usuário pode delegar para ele mesmo, caso queira votar
        super.delegate(user);
    }

    function delegateProposal(address user, uint256 proposalId) public returns (bool permitDelegate) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposta ja executada");

        // Checa se o usuário já delegou nesta proposta específica
        if (proposal.hasDelegated[msg.sender]) {
            revert("Ja delegou votos para esta proposta");
        }

        uint256 balance = _getVotingUnits(msg.sender);
        require(balance > 0, "nao possui saldo para delegar votos");

        // Marca como delegada
        proposal.hasDelegated[msg.sender] = true;

        // O usuário pode delegar para ele mesmo, caso queira votar
        super.delegate(user);

        // Checa se o usuário já delegou para outro usuário na mesma proposta
        if (proposal.votedDelegate[msg.sender][user]) {
            revert("Ja delegou votos para esse usuario nessa proposta");
        }

        // Marca a delegação de votos para o usuário na proposta
        return proposal.votedDelegate[msg.sender][user] = true;
    }

    // Votação em uma proposta usando o poder de voto do token,
    //obrigatoriamente tendo que ter uma quantidade delegacao para votar
    function vote(uint256 proposalId, address user) public {
        Proposal storage proposal = proposals[proposalId];

        // Verificar se a proposta já foi delegada
        if (!proposal.votedDelegate[user][msg.sender]) {
            revert ProposalNotDelegated();
        }

        // Verificar se o número de votos do usuário é suficiente
        uint256 votes = getVotes(msg.sender);
        if (votes < proposal.amount) {
            revert AmountVote(proposal.amount, votes);
        }

        // Verificar se a proposta está ativa
        require(proposal.deadline > block.timestamp, "Votacao encerrada");
        require(!proposal.executed, "Proposta ja executada");

        // Queimar os votos, seja voto delegado ou direto
        _transferVotingUnits(user, address(0), proposal.amount);

        // Somar os votos à proposta
        proposal.voteCount++;

        // Marcar a delegação como concluída para este par de endereços
        proposal.votedDelegate[user][msg.sender] = false;

        // Emitir evento de voto
        emit Voted(msg.sender, user, proposalId, proposal.voteCount);
    }

    function sellDelegate(address user, uint256 proposalId, uint256 amount) external {
        delegateProposal(user, proposalId);
        transfer(user, amount);
    }

    // Execução de uma proposta vencedora.
    // Faça as regras do seu jeito, podendo comparar duas propostas e automaticamente executar a que teve maior pontuacao.
    function executeProposal(uint256 proposalId) public onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.deadline <= block.timestamp, "Votacao ainda em andamento");
        require(!proposal.executed, "Proposta ja executada");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);

        // Adicione aqui a lógica de execução da proposta, se necessário
    }

    function getProposalCont(uint256 proposalId) external view returns (uint256 id) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.voteCount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
