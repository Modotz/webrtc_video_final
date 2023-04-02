class DataEmit {
  final String client_id;
  final String room;
  final String username;
  final String client_type;
  final String host;
  final String share;

  DataEmit(this.client_id, this.room, this.username, this.client_type, this.host, this.share);

  // DataEmit.fromJson(Map<String, dynamic> json)
  //     : client_id = json['client_id'],
  //       email = json['email'];

  // Map<String, dynamic> toJson() => {
  //   'name': name,
  //   'email': email,
  // };
}