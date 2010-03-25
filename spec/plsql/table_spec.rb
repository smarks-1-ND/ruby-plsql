require File.dirname(__FILE__) + '/../spec_helper'

describe "Table" do
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.autocommit = false
    plsql.execute <<-SQL
      CREATE TABLE test_employees (
        employee_id   NUMBER(15) NOT NULL,
        first_name    VARCHAR2(50),
        last_name     VARCHAR2(50),
        hire_date     DATE,
        created_at    TIMESTAMP,
        status        VARCHAR2(1) DEFAULT 'N'
      )
    SQL

    plsql.execute <<-SQL
      CREATE OR REPLACE TYPE t_address AS OBJECT (
        street    VARCHAR2(50),
        city      VARCHAR2(50),
        country   VARCHAR2(50)
      )
    SQL
    plsql.execute <<-SQL
      CREATE OR REPLACE TYPE t_phone AS OBJECT (
        type            VARCHAR2(10),
        phone_number    VARCHAR2(50)
      )
    SQL
    plsql.execute <<-SQL
      CREATE OR REPLACE TYPE t_phones AS VARRAY(10) OF T_PHONE
    SQL
    plsql.execute <<-SQL
      CREATE TABLE test_employees2 (
        employee_id   NUMBER(15) NOT NULL,
        first_name    VARCHAR2(50),
        last_name     VARCHAR2(50),
        hire_date     DATE DEFAULT SYSDATE,
        address       t_address,
        phones        t_phones
      )
    SQL
    @employees = (1..10).map do |i|
      {
        :employee_id => i,
        :first_name => "First #{i}",
        :last_name => "Last #{i}",
        :hire_date => Time.local(2000,01,i),
        :created_at => Time.local(2000,01,i,9,15,30,i),
        :status => 'A'
      }
    end
    @employees_all_fields = [:employee_id, :first_name, :last_name, :hire_date, :created_at, :status]
    @employees_all_values = @employees.map{|e| @employees_all_fields.map{|f| e[f]}}
    @employees_some_fields = [:employee_id, :first_name, :last_name]
    @employees_some_values = @employees.map{|e| @employees_some_fields.map{|f| e[f]}}
    @employee_default_values = {:hire_date => nil, :created_at => nil, :status => 'N'}

    @employees2 = (1..10).map do |i|
      {
        :employee_id => i,
        :first_name => "First #{i}",
        :last_name => "Last #{i}",
        :hire_date => Time.local(2000,01,i),
        :address => {:street => "Street #{i}", :city => "City #{i}", :country => "County #{i}"},
        :phones => [{:type => "mobile", :phone_number => "Mobile#{i}"}, {:type => "fixed", :phone_number => "Fixed#{i}"}]
      }
    end
  end

  after(:all) do
    plsql.execute "DROP TABLE test_employees"
    plsql.execute "DROP TABLE test_employees2"
    plsql.execute "DROP TYPE t_phones"
    plsql.execute "DROP TYPE t_phone"
    plsql.execute "DROP TYPE t_address"
    plsql.logoff
  end

  after(:each) do
    plsql.rollback
  end

  describe "find" do

    it "should find existing table" do
      PLSQL::Table.find(plsql, :test_employees).should_not be_nil
    end

    it "should not find nonexisting table" do
      PLSQL::Table.find(plsql, :qwerty123456).should be_nil
    end

    it "should find existing table in schema" do
      plsql.test_employees.should be_a(PLSQL::Table)
    end

  end

  describe "synonym" do

    before(:all) do
      plsql.execute "CREATE SYNONYM test_employees_synonym FOR hr.test_employees"
    end

    after(:all) do
      plsql.execute "DROP SYNONYM test_employees_synonym" rescue nil
    end

    it "should find synonym to table" do
      PLSQL::Table.find(plsql, :test_employees_synonym).should_not be_nil
    end

    it "should find table using synonym in schema" do
      plsql.test_employees_synonym.should be_a(PLSQL::Table)
    end

  end

  describe "public synonym" do

    it "should find public synonym to table" do
      PLSQL::Table.find(plsql, :dual).should_not be_nil
    end

    it "should find table using public synonym in schema" do
      plsql.dual.should be_a(PLSQL::Table)
    end

  end

  describe "columns" do

    it "should get column names for table" do
      plsql.test_employees.column_names.should == @employees_all_fields
    end

    it "should get columns metadata for table" do
      plsql.test_employees.columns.should == {
        :employee_id => {
          :position=>1, :data_type=>"NUMBER", :data_length=>22, :data_precision=>15, :data_scale=>0, :char_used=>nil,
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => false, :data_default => nil},
        :first_name => {
          :position=>2, :data_type=>"VARCHAR2", :data_length=>50, :data_precision=>nil, :data_scale=>nil, :char_used=>"B",
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :last_name => {
          :position=>3, :data_type=>"VARCHAR2", :data_length=>50, :data_precision=>nil, :data_scale=>nil, :char_used=>"B",
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :hire_date => {
          :position=>4, :data_type=>"DATE", :data_length=>7, :data_precision=>nil, :data_scale=>nil, :char_used=>nil,
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :created_at => {
          :position=>5, :data_type=>"TIMESTAMP", :data_length=>11, :data_precision=>nil, :data_scale=>6, :char_used=>nil,
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :status => {
          :position=>6, :data_type=>"VARCHAR2", :data_length=>1, :data_precision=>nil, :data_scale=>nil, :char_used=>"B",
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => "'N'"}
      }
    end

    it "should get columns metadata for table with object columns" do
      plsql.test_employees2.columns.should == {
        :employee_id => {
          :position=>1, :data_type=>"NUMBER", :data_length=>22, :data_precision=>15, :data_scale=>0, :char_used=>nil,
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => false, :data_default => nil},
        :first_name => {
          :position=>2, :data_type=>"VARCHAR2", :data_length=>50, :data_precision=>nil, :data_scale=>nil, :char_used=>"B",
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :last_name => {
          :position=>3, :data_type=>"VARCHAR2", :data_length=>50, :data_precision=>nil, :data_scale=>nil, :char_used=>"B",
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => nil},
        :hire_date => {
          :position=>4, :data_type=>"DATE", :data_length=>7, :data_precision=>nil, :data_scale=>nil, :char_used=>nil,
          :type_owner=>nil, :type_name=>nil, :sql_type_name=>nil, :nullable => true, :data_default => "SYSDATE"},
        :address => {
          :position=>5, :data_type=>"OBJECT", :data_length=>nil, :data_precision=>nil, :data_scale=>nil,
          :char_used=>nil, :type_owner=>"HR", :type_name=>"T_ADDRESS", :sql_type_name=>"HR.T_ADDRESS", :nullable => true, :data_default => nil},
        :phones => {
          :position=>6, :data_type=>"TABLE", :data_length=>nil, :data_precision=>nil, :data_scale=>nil, :char_used=>nil,
          :type_owner=>"HR", :type_name=>"T_PHONES", :sql_type_name=>"HR.T_PHONES", :nullable => true, :data_default => nil}
      }
    end

  end

  describe "insert" do
    it "should insert a record in table" do
      plsql.test_employees.insert @employees.first
      plsql.test_employees.all.should == [@employees.first]
    end

    it "should insert a record in table using partial list of columns" do
      plsql.test_employees.insert @employees.first.except(:hire_date)
      plsql.test_employees.all.should == [@employees.first.merge(:hire_date => nil)]
    end

    it "should insert default value from table definition if value not provided" do
      plsql.test_employees.insert @employees.first.except(:status)
      plsql.test_employees.all.should == [@employees.first.merge(:status => 'N')]
    end

    it "should insert array of records in table" do
      plsql.test_employees.insert @employees
      plsql.test_employees.all("ORDER BY employee_id").should == @employees
    end

    it "should insert a record in table with object types" do
      plsql.test_employees2.insert @employees2.first
      plsql.test_employees2.all.should == [@employees2.first]
    end

    it "should insert array of records in table with object types" do
      plsql.test_employees2.insert @employees2
      plsql.test_employees2.all("ORDER BY employee_id").should == @employees2
    end

  end

  describe "insert values" do
    it "should insert a record with array of values" do
      plsql.test_employees.insert_values @employees_all_values.first
      plsql.test_employees.all.should == [@employees.first]
    end

    it "should insert a record with list of all fields and array of values" do
      plsql.test_employees.insert_values @employees_all_fields, @employees_all_values.first
      plsql.test_employees.all.should == [@employees.first]
    end

    it "should insert a record with list of some fields and array of values" do
      plsql.test_employees.insert_values @employees_some_fields, @employees_some_values.first
      plsql.test_employees.all.should == [@employees.first.merge(@employee_default_values)]
    end

    it "should insert many records with array of values" do
      plsql.test_employees.insert_values *@employees_all_values
      plsql.test_employees.all.should == @employees
    end

    it "should insert many records with list of all fields and array of values" do
      plsql.test_employees.insert_values @employees_all_fields, *@employees_all_values
      plsql.test_employees.all.should == @employees
    end

    it "should insert many records with list of some fields and array of values" do
      plsql.test_employees.insert_values @employees_some_fields, *@employees_some_values
      plsql.test_employees.all.should == @employees.map{|e| e.merge(@employee_default_values)}
    end

  end

  describe "select" do
    before(:each) do
      plsql.test_employees.insert @employees
    end

    it "should select first record in table" do
      plsql.test_employees.select(:first, "ORDER BY employee_id").should == @employees.first
      plsql.test_employees.first("ORDER BY employee_id").should == @employees.first
    end

    it "should select all records in table" do
      plsql.test_employees.select(:all, "ORDER BY employee_id").should == @employees
      plsql.test_employees.all("ORDER BY employee_id").should == @employees
      plsql.test_employees.all(:order_by => :employee_id).should == @employees
    end

    it "should select record in table using WHERE condition" do
      plsql.test_employees.select(:first, "WHERE employee_id = :1", @employees.first[:employee_id]).should == @employees.first
      plsql.test_employees.first("WHERE employee_id = :1", @employees.first[:employee_id]).should == @employees.first
      plsql.test_employees.first(:employee_id => @employees.first[:employee_id]).should == @employees.first
    end

    it "should select records in table using WHERE condition and ORDER BY sorting" do
      plsql.test_employees.all(:employee_id => @employees.first[:employee_id], :order_by => :employee_id).should == [@employees.first]
    end

    it "should select record in table using :column => nil condition" do
      employee = @employees.last.dup
      employee[:employee_id] = employee[:employee_id] + 1
      employee[:hire_date] = nil
      plsql.test_employees.insert employee
      plsql.test_employees.first("WHERE hire_date IS NULL").should == employee
      plsql.test_employees.first(:hire_date => nil).should == employee
    end

    it "should select record in table using :column => :is_null condition" do
      employee = @employees.last.dup
      employee[:employee_id] = employee[:employee_id] + 1
      employee[:hire_date] = nil
      plsql.test_employees.insert employee
      plsql.test_employees.first(:hire_date => :is_null).should == employee
    end

    it "should select record in table using :column => :is_not_null condition" do
      employee = @employees.last.dup
      employee[:employee_id] = employee[:employee_id] + 1
      employee[:hire_date] = nil
      plsql.test_employees.insert employee
      plsql.test_employees.all(:hire_date => :is_not_null, :order_by => :employee_id).should == @employees
    end

    it "should count records in table" do
      plsql.test_employees.select(:count).should == @employees.size
      plsql.test_employees.count.should == @employees.size
    end

    it "should count records in table using condition" do
      plsql.test_employees.select(:count, "WHERE employee_id <= :1", @employees[2][:employee_id]).should == 3
      plsql.test_employees.count("WHERE employee_id <= :1", @employees[2][:employee_id]).should == 3
    end

  end

  describe "update" do
    it "should update a record in table" do
      employee_id = @employees.first[:employee_id]
      plsql.test_employees.insert @employees.first
      plsql.test_employees.update :first_name => 'Test', :where => {:employee_id => employee_id}
      plsql.test_employees.first(:employee_id => employee_id)[:first_name].should == 'Test'
    end

    it "should update a record in table using String WHERE condition" do
      employee_id = @employees.first[:employee_id]
      plsql.test_employees.insert @employees
      plsql.test_employees.update :first_name => 'Test', :where => "employee_id = #{employee_id}"
      plsql.test_employees.first(:employee_id => employee_id)[:first_name].should == 'Test'
      # all other records should not be changed
      plsql.test_employees.all("WHERE employee_id > :1", employee_id) do |employee|
        employee[:first_name].should_not == 'Test'
      end
    end

    it "should update all records in table" do
      plsql.test_employees.insert @employees
      plsql.test_employees.update :first_name => 'Test'
      plsql.test_employees.all do |employee|
        employee[:first_name].should == 'Test'
      end
    end

    it "should update a record in table with object type" do
      employee = @employees2[0]
      employee2 = @employees2[1]
      plsql.test_employees2.insert employee
      plsql.test_employees2.update :address => employee2[:address], :phones => employee2[:phones], :where => {:employee_id => employee[:employee_id]}
      updated_employee = plsql.test_employees2.first(:employee_id => employee[:employee_id])
      updated_employee[:address].should == employee2[:address]
      updated_employee[:phones].should == employee2[:phones]
    end

  end

  describe "delete" do
    it "should delete record from table" do
      employee_id = @employees.first[:employee_id]
      plsql.test_employees.insert @employees
      plsql.test_employees.delete :employee_id => employee_id
      plsql.test_employees.first(:employee_id => employee_id).should be_nil
      plsql.test_employees.all(:order_by => :employee_id).should == @employees[1, @employees.size-1]
    end

    it "should delete all records from table" do
      plsql.test_employees.insert @employees
      plsql.test_employees.delete
      plsql.test_employees.all.should be_empty
    end
  end

end
