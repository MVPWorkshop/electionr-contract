const Election = artifacts.require('Election');

contract('Election', (accounts) => {
  beforeEach(async () => {
    this.election = await Election.new();
  });

  describe('<function_name>', () => {
    describe('<situation>', () => {
      it('<expected_result>', async () => {
      });
    });
  });
});
