// SPDX-License-Identifier: MIT
/*solhint-disable compiler-version */
pragma solidity ^0.8.20;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {FanToken} from "../src/FanToken.sol";

contract FanTokenTest is Test {
    FanToken public fanToken;

    //gerando enderecos para interagir
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    address public owner = makeAddr("owner");

    address public userOut = makeAddr("userOut");

    function setUp() public {
        //Managemet do contrato de claimIssuer identidades deve ser o mesmo
        vm.startBroadcast(owner);

        fanToken = new FanToken(owner);

        vm.stopBroadcast();
    }

    function testContractFanToken() public {
        //variaveis
        uint256 amountUser1 = 8;
        uint256 amountUser2 = 10;
        string memory proposal = "Acesso a area VIP estadio";
        uint256 amountProposal = 5;
        uint256 timeProposal = 604800;

        vm.prank(owner);
        fanToken.mint(user1, amountUser1);

        vm.prank(owner);
        fanToken.mint(user2, amountUser2);

        //Nessa primeira etapa eh o entendimento de delegacao de votos do contrato ERC20.sol

        vm.prank(user1); // user1 tem token e pode delegar a quantidade total que ele possui sem transferir de fato o token.
        vm.warp(1708112451);
        fanToken.delegate(user2);
        console.log("timestamp:", fanToken.clock());
        assertEq(amountUser1, fanToken.getVotes(user2));

        vm.prank(user1);
        vm.warp(1708112451);
        fanToken.delegate(user1);
        assertEq(amountUser1, fanToken.getVotes(user1));
        //se esta deleganto para si mesmo ele queima a delegacao anterior
        console.log("user1 votes deve ser 8:", fanToken.getVotes(user1));
        console.log("user2 votes deve ser 0:", fanToken.getVotes(user2));

        vm.prank(user1);
        vm.warp(1708112451);
        fanToken.delegate(user2);
        //se decidir delegar novamente para outro endereco
        console.log("user1 votes deve ser 0:", fanToken.getVotes(user1));
        console.log("user2 votes deve ser 8:", fanToken.getVotes(user2));

        vm.warp(1708112452);
        uint256 VotosAnteriores = fanToken.getPastVotes(user2, 1708112451);
        console.log("getPast:", VotosAnteriores);
        assertEq(VotosAnteriores, fanToken.getVotes(user2));
        //foi delegado do user1 para o user2 8 votos no timestamp 1708112451
        //se pegarmos a quantidade de votos delegados e compararmos com os votos delegados naquele timestamp serao iguais os valores

        console.log("user1 saldo:", fanToken.balanceOf(user1));
        console.log("user2 saldo:", fanToken.balanceOf(user2));
        //reparem que o saldo se mantem o mesmo. Direito de voto nao se transfere os tokens

        //Daqui para baixo comeca a parte de criar proposta e delegacoes de cada uma

        vm.prank(owner);
        vm.warp(1708112451); // quando comecou, ou seja o prazo final sera: 1708112451 + 604800
        uint256 proposalId = fanToken.createProposal(proposal, timeProposal, amountProposal); //retorna o Id da proposta
        //criando proposta

        vm.prank(user2); //user 2 com seus 10 tokens vai delegar para o owner na proposta criada
        vm.warp(1708112460);
        fanToken.delegateProposal(owner, proposalId);
        console.log("user2 votes deve ser 8:", fanToken.getVotes(user2)); //ele ainda continua com os 8 delegados anteriormente
        console.log("owner votes deve ser 10:", fanToken.getVotes(owner)); //recebe 10

        vm.warp(1708112460); //passou pouco tempo apos a criacao da proposta
        vm.prank(owner);
        fanToken.vote(proposalId, user2); //quem delegou foi o user2
        console.log("owner votes deve ser 5:", fanToken.getVotes(owner));
        //tinha 10 delegado e queima 5

        vm.prank(user1); //user 1 tem 8 tokens ainda e nao tinha usado para nenhuma proposta
        vm.warp(1708112460);
        fanToken.delegateProposal(user1, proposalId);
        console.log("user1 votes delegate user1 (para ele mesmo) 8:", fanToken.getVotes(user1));

        vm.warp(1708112460); //passou pouco tempo apos a criacao da proposta
        vm.prank(user1);
        fanToken.vote(proposalId, user1); //ele tem 8 tokens
        console.log("user1 votes deve ser 3:", fanToken.getVotes(user1));

        uint256 votosProposal = fanToken.getProposalCont(proposalId);
        assertEq(votosProposal, 2);

        //esperamos reverter:

        vm.warp(1708112460); //passou pouco tempo apos a criacao da proposta
        vm.prank(user1);
        vm.expectRevert(); //ele ja tinha delegado esperamos que reverta
        fanToken.delegateProposal(user1, proposalId);

        vm.warp(1708112460); //passou pouco tempo apos a criacao da proposta
        vm.prank(user1);
        vm.expectRevert();
        //o user1 agora nao tem mais delegacoes suficientes para votar
        fanToken.vote(proposalId, user1);

        vm.warp(1708112460); //passou pouco tempo apos a criacao da proposta
        vm.prank(owner);
        vm.expectRevert(); //esperamos reverter pq ja tivemos o voto de delegacao entre user2 e owner
        //obrigando a ter novas permissoes para o voto
        fanToken.vote(proposalId, user2);
        console.log("owner votes deve ser 5:", fanToken.getVotes(owner));

        //vamos tentar finalizar a proposta antes do prazo
        vm.prank(owner);
        vm.warp(1708717249);
        vm.expectRevert();
        fanToken.executeProposal(proposalId); //finalizada

        ///finalizando e criando outra

        //finalizar no prazo
        vm.prank(owner);
        vm.warp(1708717251); //1708112451 + 604800 = 1708717251
        fanToken.executeProposal(proposalId); //finalizada

        vm.prank(owner);
        vm.warp(1708717251); // quando comecou, ou seja o prazo final sera: 1708717251 + 604800
        uint256 proposalId2 = fanToken.createProposal(proposal, timeProposal, amountProposal); //retorna o Id da proposta
        //criando proposta 2

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(owner); //delega a nova para ele mesmo
        vm.expectRevert(); //o owner nao tem token para delegar votos
        fanToken.delegateProposal(user1, proposalId2);

        vm.warp(1708717252);
        vm.prank(owner);
        fanToken.mint(owner, 5); //assim, ele minta para a carteira dele

        vm.warp(1708717252);
        vm.prank(owner);
        fanToken.mint(userOut, 5); //minta para o out

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(user1); //delega a nova para ele mesmo
        fanToken.delegateProposal(user1, proposalId2);
        // o user so tem 3 votes pq ja usou antes 5

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(user1); //delega a nova para ele mesmo
        vm.expectRevert();
        fanToken.vote(proposalId2, user1);

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(owner); //delega para o
        fanToken.delegateProposal(user1, proposalId2);
        console.log("user1 votes deve ser 8:", fanToken.getVotes(user1));
        // ele ja tinha 3 e somou com os 5

        vm.warp(1708717252);
        vm.prank(user1); //o usar vota com os valores delegados pelo owner
        fanToken.vote(proposalId2, owner);
        console.log("user1 votes deve ser 3:", fanToken.getVotes(user1));
        //mesmo que owner ainda tenha 5, ele ja delegou:

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(owner);
        vm.expectRevert(); //ja delegou os votos da proposta
        fanToken.delegateProposal(owner, proposalId2);

        vm.warp(1708717252);
        vm.prank(owner); //mesmo que ele tente votar precisa da delegacao
        vm.expectRevert(); //reverte pq precisa delegar, mas ja fez isso
        fanToken.vote(proposalId2, owner);

        //O owner quer votar mais pq essa proposta eh do interesse dele.
        //O que ele faz?
        //Compra do userOut os tokens e com isso ja possui a delegacao para votar novamente

        vm.warp(1708717252); //passou pouco tempo apos a criacao da proposta
        vm.prank(userOut); //delega para
        fanToken.sellDelegate(owner, proposalId2, 5);
        //o userOut com + 5 tokens delega para owner
        ///qual motivo? isso obriga a vender entre os outros participantes
        console.log("balance owner deve ser 10, sendo que comprou mais 5:", fanToken.balanceOf(owner));
        console.log(
            "vote owner deve ser 5, mas ele nao pode mais votar por ele mesmo ou de delegacoes anteriores:",
            fanToken.getVotes(owner)
        );
        console.log("userOut balance deve ser 0:", fanToken.balanceOf(userOut));
        console.log("vote userOut deve ser 0:", fanToken.getVotes(userOut));

        vm.warp(1708717252);
        vm.prank(owner); //o owner ainda nao recebeu delegacao do userOut e assim pode votar novamente, soh que por delegacao agora.
        fanToken.vote(proposalId2, userOut);
        //Ele pode repetir o processo com outros.

        //Dessa forma, temos um sistema de votacao em que so podemos votar uma vez a cada delegacao, tendo a quantidade correta referente a proposta
        //Caso o usuario queira votar mais, ou seja, a votacao seja do seu interesse, obriga a efetuar compras de tokens de outros usuarios que tenham tokens.
    }
}
