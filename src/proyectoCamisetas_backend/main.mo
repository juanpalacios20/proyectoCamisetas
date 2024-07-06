//Realizando importaciones
import Types "types";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Principal "mo:base/Principal";

actor {
  //definición de las variables a utilizar
  stable var camisetas : [Types.Camisetas] = [];
  stable var nextCamisetaId : Nat = 1;
  stable var nextRecompensaId : Nat = 1;
  stable var usuarios : [Types.Usuario] = [];
  stable var recompensas : [Types.Recompensas] = [];

  // Función para calcular Loyalty Tokens donde se da 1 token cada 100000 pesos gastados
  func calcularLoyaltyTokens(monto : Float) : Float {
    return (monto / 100000.0);
  };

  // Función para encontrar un usuario por Principal, se utiliza para ahorrar lineas de codigo
  func encontrarUsuario(usuarioId : Principal) : ?Types.Usuario {
    for (usuario in usuarios.vals()) {
      if (usuario.id == usuarioId) {
        return ?usuario;
      };
    };
    return null;
  };

  // Función para actualizar un usuario
  func actualizarUsuario(usuario : Types.Usuario) {
    usuarios := Array.filter <Types.Usuario> (usuarios, func(u) { u.id != usuario.id });
    usuarios := Array.append(usuarios, [usuario]);
  };

  //para guardar la identidad del usuario
  public func m1_registrarUsuario(usuarioId : Principal) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    //ciclo
    switch (usuarioOpt) {
      //si encuentra el usuario en la lista, el usuario ya se registró
      case (?_) {
        return #err("El usuario ya está registrado");
      };
      // en caso tal usuarioOpt sea vacio, significa que el usuario no se encontró
      case null {
        let nuevoUsuario : Types.Usuario = {
          var id = usuarioId;
          var wallet = { var saldo = 0.0 };
          var loyaltyTokens = 0.0;
          var compras = [];
        };
        usuarios := Array.append(usuarios, [nuevoUsuario]);
        return #ok("Usuario registrado con éxito");
      };
    };
  };

  //metodo para conocer la cantidad de tokens del usuario
  public query func m3_obtenerLoyaltyTokens(usuarioId : Principal) : async Result.Result<Float, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    switch (usuarioOpt) {
      case (?usuario) {
        return #ok(usuario.loyaltyTokens);
      };
      case null {
        return #err("Usuario no encontrado");
      };
    };
  };

  //Depositar dinero en la wallet
  public func m2_depositarEnWallet(usuarioId : Principal, monto : Float) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    switch (usuarioOpt) {
      case (?usuario) {
        let mutableWallet = usuario.wallet;
        mutableWallet.saldo += monto;

        let usuarioActualizado : Types.Usuario = {
          var id = usuario.id;
          var wallet = mutableWallet;
          var loyaltyTokens = usuario.loyaltyTokens;
          var compras = usuario.compras;
        };

        actualizarUsuario(usuarioActualizado);
        return #ok("Depósito realizado con éxito, " # "Nuevo saldo: " # Float.toText(mutableWallet.saldo));
      };
      case null {
        return #err("Usuario no encontrado");
      };
    };
  };

  //metodo para consultar el saldo de dinero en la wallet
  public func m3_visualizarSaldoWallet(usuarioId : Principal) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    switch (usuarioOpt) {
      case (?usuario) {
        return #ok("El saldo actual es: " # Float.toText(usuario.wallet.saldo));
      };
      case null {
        return #err("Usuario no encontrado");
      };
    };
  };

  //metodo para agregar una nueva camiseta, edición es la temporada a la que pertenece la camiseta
  //por ejemplo HOME-2024 o si es una edición retro, especial, etc.
  public func m4_agregar_camiseta(c_equipo : Text, c_talla : Text, c_edicion : Text, c_precio : Float, c_existencias : Nat) : async Result.Result<Text, Text> {
    let c_id = nextCamisetaId;
    let nueva_camiseta : Types.Camisetas = {
      var id = c_id;
      var equipo = c_equipo;
      var talla = c_talla;
      var edicion = c_edicion;
      var precio = c_precio;
      var existencias = c_existencias;
    };
    camisetas := Array.append(camisetas, [nueva_camiseta]);
    nextCamisetaId += 1;
    return #ok("Camiseta agregada con éxito");
  };

  //Agregar una neuva recompensa, donde dice el nombre de la recompensa y el costo en tokens
  public func m4_agregar_Recompensa(r_nombre : Text, r_costo : Float) : async Result.Result<Text, Text> {
    let r_id = nextRecompensaId;
    let nueva_recompensa : Types.Recompensas = {
      var id = r_id;
      var nombre = r_nombre;
      var costoTokens = r_costo;
    };
    recompensas := Array.append(recompensas, [nueva_recompensa]);
    nextRecompensaId += 1;
    return #ok("Recompensa agregada con éxito");
  };

  //metodo para consultar las camisetas existentes
  public query func m3_camisetasExistentes() : async Text {
    var mensaje : Text = "";
    for (camiseta in camisetas.vals()) {
      var informacion = "Id: " # Nat.toText(camiseta.id) # " Equipo: " # camiseta.equipo # " , Talla: " # camiseta.talla # " , Edición: " # camiseta.edicion # " , Precio: " # Float.toText(camiseta.precio) # " , Existencias: " # Nat.toText(camiseta.existencias) # " - ";
      mensaje := mensaje # "  " # informacion;
    };
    return mensaje;
  };

  //metodo para realizar la venta de la camiseta
  public func m5_realizarVenta(usuarioId : Principal, camisetaId : Nat) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    var camisetaOpt : ?Types.Camisetas = null;

    for (camiseta in camisetas.vals()) {
      if (camiseta.id == camisetaId) {
        camisetaOpt := ?camiseta;
      };
    };

    switch (usuarioOpt, camisetaOpt) {
      case (?usuario, ?camiseta) {
        if (usuario.wallet.saldo >= camiseta.precio and camiseta.existencias > 0) {
          usuario.wallet.saldo -= camiseta.precio;
          camiseta.existencias := camiseta.existencias - 1;
          usuario.compras := Array.append(usuario.compras, [camiseta]);

          let tokensGanados = calcularLoyaltyTokens(camiseta.precio);
          usuario.loyaltyTokens += tokensGanados;

          actualizarUsuario(usuario);
          return #ok("Compra realizada con éxito, " # "Nuevo saldo: " # Float.toText(usuario.wallet.saldo));
        } else {
          return #err("Saldo insuficiente o sin existencias, " # "Su saldo es: " # Float.toText(usuario.wallet.saldo) # " Las existencias son: " # Nat.toText(camiseta.existencias));
        };
      };
      case _ {
        return #err("Usuario o camiseta no encontrados");
      };
    };
  };

  //metodo para devolver una camiseta ya comprada, regresa el dinero a la wallet, la camiseta a la lista
  //y descuenta los tokens
  public func m6_devolverCamiseta(usuarioId : Principal, camisetaId : Nat) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    var camisetaOpt : ?Types.Camisetas = null;

    for (camiseta in camisetas.vals()) {
      if (camiseta.id == camisetaId) {
        camisetaOpt := ?camiseta;
      };
    };

    switch (usuarioOpt, camisetaOpt) {
      case (?usuario, ?camiseta) {
        let indexOpt = Array.indexOf<Types.Camisetas>(camiseta, usuario.compras, func(c, target) { c.id == target.id });
        switch (indexOpt) {
          case (?index) {
            usuario.compras := Array.filter<Types.Camisetas>(usuario.compras, func(c) { c.id != camisetaId });
            usuario.wallet.saldo += camiseta.precio;
            camiseta.existencias := camiseta.existencias + 1;

            let tokensRestados = calcularLoyaltyTokens(camiseta.precio);
            usuario.loyaltyTokens -= tokensRestados;

            actualizarUsuario(usuario);
            return #ok("Devolución realizada con éxito, " # "Nuevo saldo: " # Float.toText(usuario.wallet.saldo));
          };
          case null {
            return #err("La camiseta no está en las compras del usuario");
          };
        };
      };
      case _ {
        return #err("Usuario o camiseta no encontrados");
      };
    };
  };

  //metodo que permite visualizar las recompensas existentes
  public query func m3_visualizar_recompensas() : async Text {
    var mensaje : Text = "";
    for (recompensa in recompensas.vals()) {
      var informacion = "Id: " # Nat.toText(recompensa.id) # " Nombre: " # recompensa.nombre # " , Precio: " # Float.toText(recompensa.costoTokens) # " tokens " # " - ";
      mensaje := mensaje # "  " # informacion;
    };
    return mensaje;
  };

  //metodo que permite reclamar la recompensa
  public func m5_Recompensa(usuarioId : Principal, id : Nat) : async Result.Result<Text, Text> {
    let usuarioOpt = encontrarUsuario(usuarioId);
    var recompensaOpt : ?Types.Recompensas = null;

    for (recompensa in recompensas.vals()) {
      if (recompensa.id == id) {
        recompensaOpt := ?recompensa;
      };
    };

    switch (usuarioOpt, recompensaOpt) {
      case (?usuario, ?recompensa) {
        if (usuario.loyaltyTokens >= recompensa.costoTokens) {
          usuario.loyaltyTokens -= recompensa.costoTokens;
          actualizarUsuario(usuario);
          return #ok("Recompensa canjeada con éxito");
        } else {
          return #err("Tokens insuficientes");
        };
      };
      case (null, _) {
        return #err("Usuario no encontrado");
      };
      case (_, null) {
        return #err("Recompensa no encontrada");
      };
    };
  };
};
