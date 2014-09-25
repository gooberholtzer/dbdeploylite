CREATE TABLE changelog (
  change_number bigint(20) NOT NULL,
  complete_dt timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  applied_by varchar(100) NOT NULL,
  description varchar(500) NOT NULL,
  PRIMARY KEY (change_number)
);
