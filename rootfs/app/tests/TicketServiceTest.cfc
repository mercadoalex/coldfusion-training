component extends="testbox.system.BaseSpec" {

  function run() {

    describe("TicketService", function() {

      // Seed the database once before the tests are defined.
      // This TestBox version only has beforeEach/afterEach — no beforeAll.
      // Calling cfhttp here runs once when the describe closure is executed.
      cfhttp(url="http://localhost:8888/seed-db.cfm", method="GET");

      var svc = new TicketService();

      it("should return all tickets as an array", function() {
        var result = svc.getAll();
        expect(result).toBeArray();
        expect(arrayLen(result)).toBeGTE(1);
      });

      it("should return a single ticket by id", function() {
        var ticket = svc.getById(1);
        expect(ticket).toBeStruct();
        expect(ticket).toHaveKey("title");
      });

    });

  }
}
